import Foundation
import AppKit
import Combine

struct DailyTotal: Identifiable {
    let id: Date     // 날 시작점 (startOfDay)
    let date: Date
    let tokens: Int
}

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var block: BlockSummary = BlockSummary(
        summary: .zero, blockStart: nil, resetAt: nil, timeRemaining: nil
    )
    @Published var today: UsageSummary = .zero
    @Published var last7d: UsageSummary = .zero
    @Published var dailyTotals: [DailyTotal] = []
    @Published var recent: [UsageRecord] = []
    @Published var lastUpdated: Date = Date()

    private let store: UsageStore
    private let service: UsageSummaryService
    private let settings: AppSettings
    private var timer: Timer?
    private var settingsCancellable: AnyCancellable?

    init(store: UsageStore = .shared, settings: AppSettings = .shared) {
        self.store = store
        self.service = UsageSummaryService(store: store)
        self.settings = settings
        refresh()
        applyAutoRefresh()

        settingsCancellable = settings.$refreshInterval
            .removeDuplicates()
            .sink { [weak self] _ in self?.applyAutoRefresh() }
    }

    deinit { timer?.invalidate() }

    // MARK: - Derived

    var menuBarTokens: Int { block.summary.totalTokens }

    var menuBarTier: UsageTier {
        UsageTier.from(tokens: menuBarTokens, settings: settings)
    }

    var menuBarAssetName: String {
        let preferred = menuBarTier.assetName
        if NSImage(named: preferred) != nil { return preferred }
        return UsageTier.over.assetName
    }

    // MARK: - Refresh

    func refresh() {
        block  = service.currentBlockSummary()
        today  = service.todaySummary()
        last7d = service.last7DaysSummary()
        dailyTotals = computeDailyTotals()
        recent = service.recent(limit: 5)
        lastUpdated = Date()
    }

    private func applyAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: settings.refreshInterval, repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    /// 최근 7일(오늘 포함) 일별 토큰 합계.
    private func computeDailyTotals() -> [DailyTotal] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else {
            return []
        }
        let records = store.fetch(since: start)

        var buckets: [Date: Int] = [:]
        for i in 0...6 {
            if let day = cal.date(byAdding: .day, value: i, to: start) {
                buckets[day] = 0
            }
        }
        for r in records {
            let day = cal.startOfDay(for: r.createdAt)
            buckets[day, default: 0] += r.totalTokens
        }
        return buckets
            .map { DailyTotal(id: $0.key, date: $0.key, tokens: $0.value) }
            .sorted { $0.date < $1.date }
    }

}
