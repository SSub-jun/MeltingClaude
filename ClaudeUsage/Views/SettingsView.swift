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

    private var thresholdSummary: some View {
        let t = settings.userPlan.thresholds
        return VStack(alignment: .leading, spacing: 4) {
            tierRow("A · Low",   "0 – \(TokenFormatter.compact(t.low))",  .green)
            tierRow("B · Mid",   "\(TokenFormatter.compact(t.low)) – \(TokenFormatter.compact(t.mid))",  .yellow)
            tierRow("C · High",  "\(TokenFormatter.compact(t.mid)) – \(TokenFormatter.compact(t.high))", .orange)
            tierRow("D · Over",  "\(TokenFormatter.compact(t.high))+",    .red)
        }
        .padding(.top, 4)
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
