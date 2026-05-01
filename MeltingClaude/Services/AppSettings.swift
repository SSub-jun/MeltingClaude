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

    private init() {
        let stored = d.double(forKey: "refreshInterval")
        self.refreshInterval = stored == 0 ? 5 : stored
        self.userPlan = (d.string(forKey: "userPlan")).flatMap { UserPlan(rawValue: $0) } ?? .pro
        self.hasOnboarded = d.bool(forKey: "hasOnboarded")
    }

    // 임계값은 항상 플랜에서 파생 (사용자 직접 입력 없음)
    var tierLowMax: Int  { userPlan.thresholds.low }
    var tierMidMax: Int  { userPlan.thresholds.mid }
    var tierHighMax: Int { userPlan.thresholds.high }

    func resetToDefaults() {
        refreshInterval = 5
        userPlan = .pro
    }
}
