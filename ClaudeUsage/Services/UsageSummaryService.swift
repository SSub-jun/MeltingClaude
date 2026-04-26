import Foundation

struct UsageSummary {
    let totalTokens: Int
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
    let recordCount: Int

    static let zero = UsageSummary(
        totalTokens: 0, inputTokens: 0, outputTokens: 0,
        costUSD: 0, recordCount: 0
    )
}

struct BlockSummary {
    let summary: UsageSummary
    let blockStart: Date?       // 추정된 5h 블록 시작점
    let resetAt: Date?          // blockStart + 5h
    let timeRemaining: TimeInterval?
}

struct UsageSummaryService {
    let store: UsageStore

    static let blockDuration: TimeInterval = 5 * 60 * 60   // 5시간
    static let idleGapForNewBlock: TimeInterval = 60 * 60  // 1시간 공백 → 새 블록

    func todaySummary() -> UsageSummary {
        let start = Calendar.current.startOfDay(for: Date())
        return summary(from: store.fetch(since: start))
    }

    func last7DaysSummary() -> UsageSummary {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return summary(from: store.fetch(since: start))
    }

    /// 5시간 블록: 최근 5h 안의 record들 중,
    /// 1h 이상 공백 뒤의 첫 record를 블록 시작으로 추정.
    /// (record 없으면 nil 블록 반환)
    func currentBlockSummary(now: Date = Date()) -> BlockSummary {
        let windowStart = now.addingTimeInterval(-Self.blockDuration)
        // 최근 5h 안의 record (오래된→최신 정렬을 위해 reverse)
        let recent = store.fetch(since: windowStart).reversed()
        let arr = Array(recent)

        guard !arr.isEmpty else {
            return BlockSummary(summary: .zero, blockStart: nil,
                                resetAt: nil, timeRemaining: nil)
        }

        // 1h 이상 공백 뒤 첫 record 찾기 (오래된 순회)
        var blockStartIdx = 0
        for i in 1..<arr.count {
            let gap = arr[i].createdAt.timeIntervalSince(arr[i - 1].createdAt)
            if gap >= Self.idleGapForNewBlock {
                blockStartIdx = i
            }
        }

        let blockRecords = Array(arr[blockStartIdx...])
        let blockStart = blockRecords.first!.createdAt
        let resetAt = blockStart.addingTimeInterval(Self.blockDuration)
        let remaining = max(0, resetAt.timeIntervalSince(now))

        return BlockSummary(
            summary: summary(from: blockRecords),
            blockStart: blockStart,
            resetAt: resetAt,
            timeRemaining: remaining
        )
    }

    func recent(limit: Int = 5) -> [UsageRecord] {
        store.fetch(limit: limit)
    }

    private func summary(from records: [UsageRecord]) -> UsageSummary {
        UsageSummary(
            totalTokens:  records.reduce(0) { $0 + $1.totalTokens },
            inputTokens:  records.reduce(0) { $0 + $1.inputTokens },
            outputTokens: records.reduce(0) { $0 + $1.outputTokens },
            costUSD:      records.reduce(0.0) { $0 + $1.estimatedCostUSD },
            recordCount:  records.count
        )
    }
}
