import Foundation

enum UserPlan: String, CaseIterable, Identifiable {
    case pro
    case max5
    case max20
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pro:    return "Claude Pro"
        case .max5:   return "Claude Max 5×"
        case .max20:  return "Claude Max 20×"
        case .custom: return "Custom"
        }
    }

    var shortName: String {
        switch self {
        case .pro:    return "Pro"
        case .max5:   return "Max 5×"
        case .max20:  return "Max 20×"
        case .custom: return "Custom"
        }
    }

    /// 5h 블록 토큰 임계값 (low / mid / high).
    /// 추정치 — Anthropic 이 정확한 한도를 공개하지 않아 가이드용.
    /// .custom 은 AppSettings.customTier* 값을 쓰며 이 함수는 placeholder 만 반환.
    var thresholds: (low: Int, mid: Int, high: Int) {
        switch self {
        case .pro:    return (50_000,    150_000,   300_000)
        case .max5:   return (250_000,   750_000,   1_500_000)
        case .max20:  return (1_000_000, 3_000_000, 6_000_000)
        case .custom: return (0, 0, 0)   // placeholder — AppSettings 가 분기
        }
    }
}
