import Foundation

enum UsageTier: String, CaseIterable {
    case low, mid, high, over

    var assetName: String {
        switch self {
        case .low:  return "menubar-low"
        case .mid:  return "menubar-mid"
        case .high: return "menubar-high"
        case .over: return "menubar-over"
        }
    }

    /// 사용자에게 보이는 라벨
    var label: String {
        switch self {
        case .low:  return "OK"
        case .mid:  return "Active"
        case .high: return "Heavy"
        case .over: return "At limit"
        }
    }

    static func from(tokens: Int, settings: AppSettings) -> UsageTier {
        if tokens >= settings.tierHighMax { return .over }
        if tokens >= settings.tierMidMax  { return .high }
        if tokens >= settings.tierLowMax  { return .mid }
        return .low
    }
}
