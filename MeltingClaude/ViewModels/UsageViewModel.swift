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
    @Published var menuBarAssetName: String = UsageTier.over.assetName

    private let store: UsageStore
    private let service: UsageSummaryService
    private let settings: AppSettings
    private var timer: Timer?
    private var settingsCancellable: AnyCancellable?
    private var animationTimer: Timer?
    private var animatingTier: UsageTier?
    private var animationFrame: Int = 0

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

    deinit {
        timer?.invalidate()
        animationTimer?.invalidate()
    }

    // MARK: - Derived

    var menuBarTokens: Int { block.summary.totalTokens }

    var menuBarTier: UsageTier {
        UsageTier.from(tokens: menuBarTokens, settings: settings)
    }

    // MARK: - Refresh

    func refresh() {
        block  = service.currentBlockSummary()
        today  = service.todaySummary()
        last7d = service.last7DaysSummary()
        dailyTotals = computeDailyTotals()
        recent = service.recent(limit: 5)
        lastUpdated = Date()
        updateMenuBarAnimation()
    }

    // MARK: - Menu bar animation
    // Tier 별 프레임 수/주기. 프레임 자산(menubar-{tier}-{n}) 없으면 단일 자산으로 폴백 →
    // 같은 값이 반복 set 되면 SwiftUI 재렌더 스킵돼서 사실상 no-op.

    private func updateMenuBarAnimation() {
        let tier = menuBarTier
        guard tier != animatingTier else { return }
        animatingTier = tier
        animationFrame = 0

        animationTimer?.invalidate()
        let interval = animationInterval(for: tier)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.advanceMenuBarFrame() }
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)

        applyAssetName(resolveAssetName(tier: tier, frame: 0))
    }

    private func advanceMenuBarFrame() {
        guard let tier = animatingTier else { return }
        animationFrame = (animationFrame + 1) % frameCount(for: tier)
        applyAssetName(resolveAssetName(tier: tier, frame: animationFrame))
    }

    private func applyAssetName(_ name: String) {
        if name != menuBarAssetName { menuBarAssetName = name }
    }

    private func resolveAssetName(tier: UsageTier, frame: Int) -> String {
        let frameName = "\(tier.assetName)-\(frame)"
        if NSImage(named: frameName) != nil { return frameName }
        if NSImage(named: tier.assetName) != nil { return tier.assetName }
        return UsageTier.over.assetName
    }

    private func frameCount(for tier: UsageTier) -> Int {
        switch tier {
        case .low:  return 2
        case .mid:  return 3
        case .high: return 4
        case .over: return 5
        }
    }

    private func animationInterval(for tier: UsageTier) -> TimeInterval {
        switch tier {
        case .low:  return 0.8
        case .mid:  return 0.5
        case .high: return 0.4
        case .over: return 0.3
        }
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
