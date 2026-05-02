import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    let ingestor: ClaudeLogIngestor
    let onFinish: () -> Void

    @State private var sessionFileCount: Int = 0
    @State private var isWorking = false
    @State private var importedCount: Int? = nil
    @State private var hasAccess: Bool = FolderAccessStore.shared.hasBookmark

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
        .frame(width: 480, height: 520)
        .onAppear { if hasAccess { refreshDetect() } }
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your plan")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                ForEach(UserPlan.allCases.filter { $0 != .custom }) { plan in
                    planButton(plan)
                }
            }

            Text("Tier thresholds: A → \(TokenFormatter.compact(settings.tierLowMax)) → \(TokenFormatter.compact(settings.tierMidMax)) → \(TokenFormatter.compact(settings.tierHighMax))+")
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

    @ViewBuilder
    private var statusBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !hasAccess {
                HStack(alignment: .top) {
                    Image(systemName: "folder.badge.questionmark")
                        .foregroundStyle(.orange)
                    Text("MeltingClaude needs read access to your ~/.claude/ folder to parse Claude Code session logs. Click the button below — macOS will ask you to confirm the folder.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if ingestor.isClaudeCodeInstalled {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Claude Code detected").font(.callout)
                }
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text("\(sessionFileCount) session file\(sessionFileCount == 1 ? "" : "s") found")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("The selected folder doesn't contain a 'projects' subfolder. Make sure you pick your ~/.claude/ folder (run Claude Code at least once first).")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
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
        if !hasAccess {
            VStack(spacing: 8) {
                Button(action: grantAccess) {
                    Text("Choose ~/.claude/ Folder")
                        .frame(minWidth: 240)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now") {
                    settings.hasOnboarded = true
                    onFinish()
                }
            }
        } else if !ingestor.isClaudeCodeInstalled {
            VStack(spacing: 8) {
                Button(action: grantAccess) {
                    Text("Choose Different Folder")
                        .frame(minWidth: 240)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now") {
                    settings.hasOnboarded = true
                    onFinish()
                }
            }
        } else {
            Button(action: connect) {
                if isWorking {
                    HStack { ProgressView().controlSize(.small); Text("Importing…") }
                        .frame(minWidth: 240)
                } else {
                    Text("Connect Claude Code")
                        .frame(minWidth: 240)
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

    private func grantAccess() {
        if FolderAccessStore.shared.requestAccess() != nil {
            hasAccess = true
            refreshDetect()
        }
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
