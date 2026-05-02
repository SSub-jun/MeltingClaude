import Foundation

/// ~/.claude/projects/<project-hash>/<sessionId>.jsonl 파일을 추적해서
/// type=assistant + message.usage 가 있는 라인을 UsageRecord 로 변환하여 SQLite 에 저장.
///
/// 동작:
///   - backfill(): 모든 파일 처음부터 다시 읽어 INSERT OR IGNORE
///   - startWatching(): 일정 주기로 파일 크기 변화를 폴링, 새 바이트만 파싱
final class ClaudeLogIngestor {
    static let shared = ClaudeLogIngestor()

    private let store: UsageStore
    private let folderAccess = FolderAccessStore.shared
    private let offsetsKey = "claudeLogIngestor.fileOffsets"
    private let queue = DispatchQueue(label: "MeltingClaude.LogIngestor")
    private var timer: Timer?
    private var fileOffsets: [String: UInt64]
    private let iso = ISO8601DateFormatter()

    private init(store: UsageStore = .shared) {
        self.store = store
        let stored = UserDefaults.standard.dictionary(forKey: offsetsKey) as? [String: NSNumber] ?? [:]
        self.fileOffsets = stored.mapValues { $0.uint64Value }
        self.iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - Public

    /// bookmark 가 있고, 그 폴더 안에 projects/ 가 존재하는가.
    var isClaudeCodeInstalled: Bool {
        folderAccess.withAccess { rootURL in
            FileManager.default.fileExists(
                atPath: rootURL.appendingPathComponent("projects").path
            )
        } ?? false
    }

    func discoverSessionFiles() -> [URL] {
        folderAccess.withAccess { rootURL in
            sessionFiles(under: rootURL)
        } ?? []
    }

    /// withAccess 안에서만 호출. rootURL = 사용자가 선택한 ~/.claude/.
    private func sessionFiles(under rootURL: URL) -> [URL] {
        let projectsDir = rootURL.appendingPathComponent("projects")
        let fm = FileManager.default
        guard fm.fileExists(atPath: projectsDir.path),
              let projects = try? fm.contentsOfDirectory(
                at: projectsDir, includingPropertiesForKeys: nil
              )
        else { return [] }

        var result: [URL] = []
        for p in projects {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: p.path, isDirectory: &isDir), isDir.boolValue {
                if let files = try? fm.contentsOfDirectory(
                    at: p, includingPropertiesForKeys: nil
                ) {
                    result.append(contentsOf: files.filter { $0.pathExtension == "jsonl" })
                }
            }
        }
        return result
    }

    /// 모든 파일을 처음부터 다시 읽어 가져옴. (offset 초기화)
    func backfill(completion: ((Int) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self else { return }
            self.fileOffsets = [:]
            let inserted = self.ingestNewLines()
            self.persistOffsets()
            DispatchQueue.main.async { completion?(inserted) }
        }
    }

    /// 폴링 시작.
    func startWatching(interval: TimeInterval = 5) {
        stopWatching()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.queue.async {
                _ = self?.ingestNewLines()
                self?.persistOffsets()
            }
        }
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Internal

    @discardableResult
    private func ingestNewLines() -> Int {
        // 한 사이클 동안 security scope 한 번만 start/stop.
        folderAccess.withAccess { rootURL in
            let files = sessionFiles(under: rootURL)
            var inserted = 0
            for f in files {
                inserted += ingest(file: f)
            }
            return inserted
        } ?? 0
    }

    private func ingest(file: URL) -> Int {
        let path = file.path
        let lastOffset = fileOffsets[path] ?? 0

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = (attrs[.size] as? NSNumber)?.uint64Value else {
            return 0
        }
        // 파일이 줄어들었으면 (rotated 등) offset 리셋
        if size < lastOffset {
            fileOffsets[path] = 0
        }
        let startOffset = fileOffsets[path] ?? 0
        guard size > startOffset else { return 0 }

        var inserted = 0
        do {
            let handle = try FileHandle(forReadingFrom: file)
            try handle.seek(toOffset: startOffset)
            let data = handle.readDataToEndOfFile()
            try? handle.close()

            // 마지막 줄이 잘렸을 수 있음 — 마지막 \n까지만 처리하고 offset 갱신
            guard let lastNewlineIdx = data.lastIndex(of: 0x0A) else {
                // 줄바꿈이 없으면 아직 한 줄도 완성 안 된 것 — 다음 폴링에서 시도
                return 0
            }
            let processable = data.prefix(through: lastNewlineIdx)
            let processedBytes = UInt64(processable.count)

            if let str = String(data: processable, encoding: .utf8) {
                for line in str.split(separator: "\n", omittingEmptySubsequences: true) {
                    if let lineData = line.data(using: .utf8),
                       parseAndInsert(jsonLine: lineData) {
                        inserted += 1
                    }
                }
            }

            fileOffsets[path] = startOffset + processedBytes
        } catch {
            print("⚠️ Ingest error \(path): \(error)")
        }
        return inserted
    }

    /// 파싱 성공 + 의미 있는 record면 INSERT 후 true.
    @discardableResult
    private func parseAndInsert(jsonLine: Data) -> Bool {
        guard let obj = try? JSONSerialization.jsonObject(with: jsonLine) as? [String: Any],
              (obj["type"] as? String) == "assistant",
              let message = obj["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any]
        else { return false }

        let model = (message["model"] as? String) ?? "unknown"

        // 외부 ID: message.id 우선, 없으면 obj.uuid
        let externalId =
            (message["id"] as? String)
            ?? (obj["uuid"] as? String)
            ?? UUID().uuidString

        let inputTokens  = (usage["input_tokens"]  as? Int) ?? 0
        let outputTokens = (usage["output_tokens"] as? Int) ?? 0
        let cacheCreate  = (usage["cache_creation_input_tokens"] as? Int) ?? 0
        let cacheRead    = (usage["cache_read_input_tokens"] as? Int) ?? 0

        // 한도 카운트: input + cache_creation + output
        // (cache_read 는 5h 한도에 카운트되지 않음 — 캐시 적중분이라 거의 무시되는 분량)
        let billableInput = inputTokens + cacheCreate
        let totalTokens = billableInput + outputTokens

        // 비용: cache_read 는 input 단가의 ~10% (Anthropic). MVP에서는 보수적으로 포함.
        let baseCost = PricingCalculator.cost(
            model: model, inputTokens: billableInput, outputTokens: outputTokens
        )
        let cacheReadPricing = PricingCalculator.pricingTable[model] ?? PricingCalculator.defaultPricing
        let cacheReadCost = Double(cacheRead) / 1_000_000 * (cacheReadPricing.inputPerMillion * 0.1)
        let totalCost = baseCost + cacheReadCost

        let timestamp: Date = {
            if let s = obj["timestamp"] as? String, let d = iso.date(from: s) {
                return d
            }
            return Date()
        }()

        let record = UsageRecord(
            id: UUID(),
            createdAt: timestamp,
            model: model,
            inputTokens: billableInput,
            outputTokens: outputTokens,
            totalTokens: totalTokens,
            estimatedCostUSD: totalCost,
            projectPath: obj["cwd"] as? String,
            source: "log-parser"
        )
        store.insertIfNew(record, externalId: externalId)
        return true
    }

    private func persistOffsets() {
        let asNumbers = fileOffsets.mapValues { NSNumber(value: $0) }
        UserDefaults.standard.set(asNumbers, forKey: offsetsKey)
    }
}
