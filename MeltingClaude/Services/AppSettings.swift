import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let d = UserDefaults.standard

    @Published var refreshInterval: TimeInterval {
        didSet { d.set(refreshInterval, forKey: "refreshInterval") }
    }

    @Published var hasOnboarded: Bool {
        didSet { d.set(hasOnboarded, forKey: "hasOnboarded") }
    }

    /// 사용자 플랜 — 5h 블록 임계값을 결정.
    @Published var userPlan: UserPlan {
        didSet { d.set(userPlan.rawValue, forKey: "userPlan") }
    }

    /// .custom 플랜 전용 임계값. 다른 플랜에선 무시됨.
    @Published var customTierLow: Int {
        didSet { d.set(customTierLow, forKey: "customTierLow") }
    }
    @Published var customTierMid: Int {
        didSet { d.set(customTierMid, forKey: "customTierMid") }
    }
    @Published var customTierHigh: Int {
        didSet { d.set(customTierHigh, forKey: "customTierHigh") }
    }

    private init() {
        let stored = d.double(forKey: "refreshInterval")
        self.refreshInterval = stored == 0 ? 5 : stored
        self.userPlan = (d.string(forKey: "userPlan")).flatMap { UserPlan(rawValue: $0) } ?? .pro
        self.hasOnboarded = d.bool(forKey: "hasOnboarded")

        // custom 값은 0이면 Pro 임계값으로 시드
        let storedLow  = d.integer(forKey: "customTierLow")
        let storedMid  = d.integer(forKey: "customTierMid")
        let storedHigh = d.integer(forKey: "customTierHigh")
        let proT = UserPlan.pro.thresholds
        self.customTierLow  = storedLow  == 0 ? proT.low  : storedLow
        self.customTierMid  = storedMid  == 0 ? proT.mid  : storedMid
        self.customTierHigh = storedHigh == 0 ? proT.high : storedHigh
    }

    // 임계값: .custom 이면 사용자 입력값, 아니면 플랜 파생값
    var tierLowMax: Int  {
        userPlan == .custom ? customTierLow  : userPlan.thresholds.low
    }
    var tierMidMax: Int  {
        userPlan == .custom ? customTierMid  : userPlan.thresholds.mid
    }
    var tierHighMax: Int {
        userPlan == .custom ? customTierHigh : userPlan.thresholds.high
    }

    func resetToDefaults() {
        refreshInterval = 5
        userPlan = .pro
    }
}
