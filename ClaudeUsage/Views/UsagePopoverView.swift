import SwiftUI
import Charts

struct UsagePopoverView: View {
    @ObservedObject var vm: UsageViewModel
    @ObservedObject var settings: AppSettings = .shared
    @Environment(\.openSettings) private var openSettings
    @State private var isRecentExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Claude Usage")
                .font(.headline)

            Divider()
            blockSection
            Divider()
            weekSection
            Divider()
            todaySection
            Divider()
            recentSection
            Divider()

            actionButtons

            Text("Last updated: \(vm.lastUpdated.formatted(date: .omitted, time: .standard))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 340)
    }

    // MARK: - 5h block

    private var blockSection: some View {
        let total = vm.block.summary.totalTokens
        let cap = max(1, settings.tierHighMax)
        let progress = min(1.0, Double(total) / Double(cap))
        let color = tierColor(for: total)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current 5h block")
                    .font(.subheadline.bold())
                Spacer()
                Text(vm.menuBarTier.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2), in: Capsule())
                    .foregroundStyle(color)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(TokenFormatter.full(total)) / \(TokenFormatter.compact(cap))")
                    .font(.caption)
                Spacer()
                if let remaining = vm.block.timeRemaining {
                    Text("Block resets in \(DurationFormatter.hm(remaining))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No activity yet — start a Claude Code session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 7 days

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Last 7 days").font(.subheadline.bold())
                Spacer()
                Text("\(TokenFormatter.full(vm.last7d.totalTokens)) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(vm.dailyTotals) { d in
                BarMark(
                    x: .value("Day", d.date, unit: .day),
                    y: .value("Tokens", d.tokens)
                )
                .foregroundStyle(tierColor(for: d.tokens))
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        HStack {
            Text("Today").font(.subheadline.bold())
            Spacer()
            Text("\(TokenFormatter.full(vm.today.totalTokens)) tokens · \(vm.today.recordCount) messages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Recent (collapsible)

    private var recentSection: some View {
        DisclosureGroup(isExpanded: $isRecentExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if vm.recent.isEmpty {
                    Text("No records yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.recent) { r in
                        HStack {
                            Text(r.model)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Text(TokenFormatter.compact(r.totalTokens))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Recent").font(.subheadline.bold())
                Text("(\(vm.recent.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack {
            Button("Refresh") { vm.refresh() }
            Spacer()
            Button("Settings") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
    }

    // MARK: - Color

    private func tierColor(for tokens: Int) -> Color {
        let tier = UsageTier.from(tokens: tokens, settings: settings)
        switch tier {
        case .low:  return .green
        case .mid:  return .yellow
        case .high: return .orange
        case .over: return .red
        }
    }
}
