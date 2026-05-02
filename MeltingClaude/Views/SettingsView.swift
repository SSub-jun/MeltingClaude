import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Plan") {
                Picker("Subscription", selection: $settings.userPlan) {
                    ForEach(UserPlan.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.menu)

                thresholdSummary
            }

            Section("Refresh") {
                Stepper(
                    value: $settings.refreshInterval, in: 1...60, step: 1
                ) {
                    Text("Auto-refresh every \(Int(settings.refreshInterval))s")
                }
            }

            Section {
                Button("Reset to defaults") { settings.resetToDefaults() }
            } footer: {
                Text("Plan thresholds are estimates — Anthropic does not publish exact rate limits, so these are guidance only.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 380)
    }

    @ViewBuilder
    private var thresholdSummary: some View {
        if settings.userPlan == .custom {
            customThresholdInputs
        } else {
            VStack(alignment: .leading, spacing: 4) {
                let lo = settings.tierLowMax
                let mi = settings.tierMidMax
                let hi = settings.tierHighMax
                tierRow("A · Low",   "0 – \(TokenFormatter.compact(lo))",  .green)
                tierRow("B · Mid",   "\(TokenFormatter.compact(lo)) – \(TokenFormatter.compact(mi))",  .yellow)
                tierRow("C · High",  "\(TokenFormatter.compact(mi)) – \(TokenFormatter.compact(hi))", .orange)
                tierRow("D · Over",  "\(TokenFormatter.compact(hi))+",    .red)
            }
            .padding(.top, 4)
        }
    }

    private var customThresholdInputs: some View {
        VStack(alignment: .leading, spacing: 6) {
            customRow(label: "A · Low cap",  color: .green,  value: $settings.customTierLow)
            customRow(label: "B · Mid cap",  color: .yellow, value: $settings.customTierMid)
            customRow(label: "C · High cap", color: .orange, value: $settings.customTierHigh)
            Text("Token thresholds. Tier 'D · Over' starts above High cap.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(.top, 4)
    }

    private func customRow(label: String, color: Color, value: Binding<Int>) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption)
            Spacer()
            TextField("0", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .font(.caption.monospacedDigit())
                .frame(width: 110)
        }
    }

    private func tierRow(_ label: String, _ range: String, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption)
            Spacer()
            Text(range).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}
