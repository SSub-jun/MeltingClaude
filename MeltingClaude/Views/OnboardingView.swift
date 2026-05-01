import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    let ingestor: ClaudeLogIngestor
    let onFinish: () -> Void

    @State private var sessionFileCount: Int = 0
    @State private var isWorking = false
    @State private var importedCount: Int? = nil

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Welcome to MeltingClaude")
                    .font(.title2.bold())
                Text("See how close you are to your Claude Code rate limit, before it cuts you off.\nReads your local session logs — no servers, no API keys.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            planPicker
            statusBox

            if let imported = importedCount {
                Text("Imported \(imported) records.")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            actionButton

            Text("Plan thresholds are estimates. You can change the plan later in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(width: 480, height: 480)
        .onAppear { refreshDetect() }
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your plan")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ForEach(UserPlan.allCases) { plan in
                    planButton(plan)
                }
            }

            let t = settings.userPlan.thresholds
            Text("Tier thresholds: A → \(TokenFormatter.compact(t.low)) → \(TokenFormatter.compact(t.mid)) → \(TokenFormatter.compact(t.high))+")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func planButton(_ plan: UserPlan) -> some View {
        let selected = settings.userPlan == plan
        return Button {
            settings.userPlan = plan
        } label: {
            VStack(spacing: 2) {
                Text(plan.shortName)
                    .font(.callout.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(selected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detection box

    private var statusBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: ingestor.isClaudeCodeInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(ingestor.isClaudeCodeInstalled ? .green : .red)
                Text(ingestor.isClaudeCodeInstalled
                     ? "Claude Code detected"
                     : "Claude Code not found at ~/.claude/projects/")
                    .font(.callout)
            }
            if ingestor.isClaudeCodeInstalled {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text("\(sessionFileCount) session file\(sessionFileCount == 1 ? "" : "s") found")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action

    @ViewBuilder
    private var actionButton: some View {
        if !ingestor.isClaudeCodeInstalled {
            HStack {
                Button("Re-check") { refreshDetect() }
                Button("Skip for now") {
                    settings.hasOnboarded = true
                    onFinish()
                }
            }
        } else {
            Button(action: connect) {
                if isWorking {
                    HStack { ProgressView().controlSize(.small); Text("Importing…") }
                        .frame(minWidth: 220)
                } else {
                    Text("Connect Claude Code")
                        .frame(minWidth: 220)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isWorking)
        }
    }

    private func refreshDetect() {
        sessionFileCount = ingestor.discoverSessionFiles().count
    }

    private func connect() {
        isWorking = true
        ingestor.backfill { count in
            importedCount = count
            isWorking = false
            settings.hasOnboarded = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinish()
            }
        }
    }
}
