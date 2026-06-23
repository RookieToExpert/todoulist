import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    private var isSelected: Bool { selectedGoalId == goal.id }
    private var hasChildren: Bool { store.hasChildren(goal) }
    private var isExpanded: Bool { expandedGoalIds.contains(goal.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center, spacing: 7) {
                expandControl

                Button {
                    store.setCompleted(goal, isCompleted: !goal.isCompleted)
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(goal.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Text(goal.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    .strikethrough(goal.isCompleted, color: .secondary)
                    .lineLimit(1)

                Spacer(minLength: 10)

                if let completedAt = goal.completedAt, goal.isCompleted {
                    Text(completionText(for: completedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if goal.isUrgent {
                    Label("加急", systemImage: "flag.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.orange.opacity(0.9))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }

                Button {
                    store.toggleUrgent(goal)
                } label: {
                    Label("加急", systemImage: goal.isUrgent ? "flag.fill" : "flag")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(goal.isUrgent ? Color.orange.opacity(0.9) : .secondary)

                childGoalMenu
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(rowBackground)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(goal.isUrgent ? Color.orange.opacity(0.55) : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(goal.isCompleted ? 0.62 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .onTapGesture {
                selectedGoalId = goal.id
            }
            .contextMenu {
                Button(goal.isCompleted ? "取消完成" : "完成") {
                    store.setCompleted(goal, isCompleted: !goal.isCompleted)
                }
                Button(goal.isUrgent ? "取消加急" : "设为加急") {
                    store.toggleUrgent(goal)
                }
                ForEach(store.allowedChildLevels(for: goal)) { childLevel in
                    Button("新增\(childLevel.displayName)") {
                        addChildGoal(level: childLevel)
                    }
                }
                Divider()
                Button("删除", role: .destructive) {
                    onDelete(goal)
                }
            }
            .padding(.leading, rowIndent)

            if isExpanded {
                GoalSiblingRows(
                    goals: store.orderedGoals(planListId: planListId, parentId: goal.id),
                    planListId: planListId,
                    levelDepth: levelDepth + 1,
                    selectedGoalId: $selectedGoalId,
                    expandedGoalIds: $expandedGoalIds,
                    store: store,
                    onDelete: onDelete
                )
            }
        }
    }

    @ViewBuilder
    private var expandControl: some View {
        if hasChildren {
            Button {
                toggleExpansion()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: 18)
            }
            .buttonStyle(.plain)
        } else {
            Spacer()
                .frame(width: 12, height: 18)
        }
    }

    private var rowIndent: CGFloat {
        CGFloat(levelDepth) * 18
    }

    @ViewBuilder
    private var childGoalMenu: some View {
        let childLevels = store.allowedChildLevels(for: goal)
        if childLevels.isEmpty {
            Button {} label: {
                Label("无可新增子目标", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(true)
        } else {
            Menu {
                ForEach(childLevels) { childLevel in
                    Button {
                        addChildGoal(level: childLevel)
                    } label: {
                        Label("新增\(childLevel.displayName)", systemImage: childLevel.accentSymbol)
                    }
                }
            } label: {
                Label("新增子目标", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var rowBackground: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.10))
        }
        if goal.isUrgent {
            return AnyShapeStyle(Color.orange.opacity(0.045))
        }
        return AnyShapeStyle(Color.clear)
    }

    private func completionText(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        return String(format: "已完成 %02d-%02d", components.month ?? 1, components.day ?? 1)
    }

    private func toggleExpansion() {
        guard hasChildren else { return }
        if isExpanded {
            expandedGoalIds.remove(goal.id)
        } else {
            expandedGoalIds.insert(goal.id)
        }
    }

    private func addChildGoal(level: GoalLevel? = nil) {
        if let child = store.createGoal(planListId: planListId, parent: goal, level: level) {
            expandedGoalIds.insert(goal.id)
            selectedGoalId = child.id
        }
    }
}

struct GoalSiblingRows: View {
    let goals: [Goal]
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    private var sections: [GoalPeriodSection] {
        GoalPeriodSection.makeSections(from: goals)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 1) {
                    periodHeader(for: section)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(section.goals) { goal in
                            GoalRowView(
                                goal: goal,
                                planListId: planListId,
                                levelDepth: levelDepth,
                                selectedGoalId: $selectedGoalId,
                                expandedGoalIds: $expandedGoalIds,
                                store: store,
                                onDelete: onDelete
                            )
                        }
                    }
                }
            }
        }
        .overlay(alignment: .leading) {
            if levelDepth > 0 && !goals.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.16))
                    .frame(width: 1)
                    .padding(.leading, guideIndent)
                    .padding(.vertical, 8)
            }
        }
    }

    private func periodHeader(for section: GoalPeriodSection) -> some View {
        Label(section.displayName, systemImage: section.systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.leading, headerIndent)
            .padding(.top, levelDepth == 0 ? 1 : 2)
    }

    private var headerIndent: CGFloat {
        CGFloat(levelDepth) * 18 + 48
    }

    private var guideIndent: CGFloat {
        CGFloat(levelDepth) * 18 + 12
    }
}

private struct GoalPeriodSection: Identifiable {
    let id: String
    let displayName: String
    let systemImage: String
    var goals: [Goal]

    static func makeSections(from goals: [Goal]) -> [GoalPeriodSection] {
        goals.reduce(into: []) { sections, goal in
            if let lastIndex = sections.indices.last,
               sections[lastIndex].id == goal.periodDisplayKey {
                sections[lastIndex].goals.append(goal)
            } else {
                sections.append(
                    GoalPeriodSection(
                        id: goal.periodDisplayKey,
                        displayName: goal.periodDisplayName,
                        systemImage: goal.level.accentSymbol,
                        goals: [goal]
                    )
                )
            }
        }
    }
}
