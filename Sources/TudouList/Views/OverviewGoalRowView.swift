import SwiftUI

struct OverviewGoalRowView: View {
    let goal: Goal
    let isSelected: Bool
    @ObservedObject var store: PlanningStore
    let onSelect: () -> Void

    private var canMoveToToday: Bool {
        goal.effectiveKind == .action &&
        !goal.isCompleted &&
        !goal.isLegacyWeekContainer &&
        (goal.effectiveActionScope == .thisWeek || goal.effectiveActionScope == .later)
    }

    private var canMoveToLater: Bool {
        goal.effectiveKind == .action &&
        !goal.isCompleted &&
        !goal.isLegacyWeekContainer &&
        goal.effectiveActionScope == .today
    }

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Button {
                store.setCompleted(goal, isCompleted: !goal.isCompleted)
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(goal.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(goal.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                        .strikethrough(goal.isCompleted, color: .secondary)
                        .lineLimit(1)

                    Text(goal.semanticDisplayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.10), in: Capsule())

                    if goal.isUrgent {
                        Label("加急", systemImage: "flag.fill")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.orange.opacity(0.9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12), in: Capsule())
                    }

                    Spacer(minLength: 0)

                    if let completedAt = goal.completedAt, goal.isCompleted {
                        Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(goal.isUrgent ? Color.orange.opacity(0.55) : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 5)
        }
        .opacity(goal.isCompleted ? 0.66 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button(goal.isCompleted ? "取消完成" : "完成") {
                store.setCompleted(goal, isCompleted: !goal.isCompleted)
            }
            Button(goal.isUrgent ? "取消加急" : "设为加急") {
                store.toggleUrgent(goal)
            }
            if canMoveToToday {
                Button("移动到今日必须") {
                    store.updateActionScope(id: goal.id, actionScope: .today)
                }
            }
            if canMoveToLater {
                Button("移回待分配") {
                    store.updateActionScope(id: goal.id, actionScope: .later)
                }
            }
        }
    }

    private var metadataText: String {
        let path = store.goalPath(for: goal)
        return path.isEmpty ? store.planListName(for: goal) : path
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.10)
        }
        if goal.isUrgent {
            return Color.orange.opacity(0.045)
        }
        return Color.clear
    }
}
