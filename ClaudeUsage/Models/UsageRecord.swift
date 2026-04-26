import Foundation

struct UsageRecord: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let estimatedCostUSD: Double
    let projectPath: String?
    let source: String   // "mock" | "cli-wrapper" | "log-parser"
}
