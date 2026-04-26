import Foundation

struct ModelPricing {
    let inputPerMillion: Double
    let outputPerMillion: Double
}

enum PricingCalculator {
    static let pricingTable: [String: ModelPricing] = [
        "claude-opus-4-7":   ModelPricing(inputPerMillion: 15.0, outputPerMillion: 75.0),
        "claude-sonnet-4-6": ModelPricing(inputPerMillion: 3.0,  outputPerMillion: 15.0),
        "claude-haiku-4-5":  ModelPricing(inputPerMillion: 0.80, outputPerMillion: 4.0),
    ]

    static let defaultPricing = ModelPricing(inputPerMillion: 3.0, outputPerMillion: 15.0)

    static func cost(model: String, inputTokens: Int, outputTokens: Int) -> Double {
        let p = pricingTable[model] ?? defaultPricing
        let inCost  = Double(inputTokens)  / 1_000_000 * p.inputPerMillion
        let outCost = Double(outputTokens) / 1_000_000 * p.outputPerMillion
        return inCost + outCost
    }
}
