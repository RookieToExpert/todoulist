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
    private var directChildren: [Goal] {
        store.orderedGoals(planListId: planListId, parentId: goal.id)
    }
    private var creationOptions: [GoalCreationOption] {
        store.childCreationOptions(for: goal)
    }
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
                ForEach(creationOptions) { option in
                    Button(option.title) {
                        addChildGoal(option: option)
                    }
                    .disabled(!option.isEnabled)
                }
                Divider()
                Button("删除", role: .destructive) {
                    onDelete(goal)
                }
            }
            .padding(.leading, rowIndent)

            if isExpanded {
                if goal.level == .month {
                    MonthGoalSections(
                        goals: directChildren,
                        planListId: planListId,
                        levelDepth: levelDepth + 1,
                        selectedGoalId: $selectedGoalId,
                        expandedGoalIds: $expandedGoalIds,
                        store: store,
                        onDelete: onDelete
                    )
                } else {
                    GoalSiblingRows(
                        goals: directChildren,
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
        if creationOptions.isEmpty {
            Button {} label: {
                Label("无可新增子目标", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(true)
        } else {
            Menu {
                ForEach(creationOptions) { option in
                    Button {
                        addChildGoal(option: option)
                    } label: {
                        Label(option.title, systemImage: symbolName(for: option))
                    }
                    .disabled(!option.isEnabled)
                }
            } label: {
                Label(menuLabelTitle, systemImage: "plus")
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

    private var menuLabelTitle: String {
        switch goal.level {
        case .year:
            return "添加阶段目标"
        case .month:
            return "添加行动"
        case .week:
            return "添加子任务"
        case .day:
            return "无可新增子目标"
        }
    }

    private func symbolName(for option: GoalCreationOption) -> String {
        guard let level = option.level else { return "clock.badge.questionmark" }
        if option.actionScope == .later {
            return "tray"
        }
        return level.accentSymbol
    }

    private func addChildGoal(option: GoalCreationOption) {
        guard let level = option.level else { return }
        if let child = store.createGoal(
            planListId: planListId,
            parent: goal,
            level: level,
            kind: option.kind,
            actionScope: option.actionScope
        ) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(goals) { goal in
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

    private var guideIndent: CGFloat {
        CGFloat(levelDepth) * 18 + 12
    }
}

private struct MonthGoalSections: View {
    let goals: [Goal]
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    private var visibleActionGoals: [Goal] {
        let directWeekGoals = goals.filter { $0.level == .week }
        let legacyChildren = directWeekGoals
            .filter(\.isLegacyWeekContainer)
            .flatMap { legacyGoal in
                store.orderedGoals(planListId: planListId, parentId: legacyGoal.id)
            }

        let directActionGoals = goals.filter {
            $0.effectiveKind == .action && !$0.isLegacyWeekContainer
        }

        return uniqueGoalsById(directActionGoals + legacyChildren)
    }

    private var dayGoals: [Goal] {
        store.sortedGoals(
            visibleActionGoals.filter { $0.effectiveActionScope == .today && !$0.isCompleted }
        )
    }

    private var allocationGoals: [Goal] {
        store.sortedGoals(
            visibleActionGoals.filter {
                ($0.effectiveActionScope == .thisWeek || $0.effectiveActionScope == .later) && !$0.isCompleted
            }
        )
    }

    private var completedGoals: [Goal] {
        store.sortedCompletedGoals(
            visibleActionGoals.filter(\.isCompleted)
        )
    }

    private func uniqueGoalsById(_ goals: [Goal]) -> [Goal] {
        var seen = Set<UUID>()
        return goals.filter { goal in
            seen.insert(goal.id).inserted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonthGoalSectionBlock(
                title: "今日必须",
                goals: dayGoals,
                emptyMessage: "暂无今日必须",
                planListId: planListId,
                levelDepth: levelDepth,
                selectedGoalId: $selectedGoalId,
                expandedGoalIds: $expandedGoalIds,
                store: store,
                onDelete: onDelete
            )

            MonthGoalSectionBlock(
                title: "待分配",
                goals: allocationGoals,
                emptyMessage: "暂无待分配",
                planListId: planListId,
                levelDepth: levelDepth,
                selectedGoalId: $selectedGoalId,
                expandedGoalIds: $expandedGoalIds,
                store: store,
                onDelete: onDelete
            )

            if !completedGoals.isEmpty {
                MonthGoalSectionBlock(
                    title: "已完成",
                    goals: completedGoals,
                    emptyMessage: "暂无已完成",
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

private struct MonthGoalSectionBlock: View {
    let title: String
    let goals: [Goal]
    let emptyMessage: String
    let planListId: UUID
    let levelDepth: Int
    @Binding var selectedGoalId: UUID?
    @Binding var expandedGoalIds: Set<UUID>
    @ObservedObject var store: PlanningStore
    let onDelete: (Goal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, sectionHeaderIndent)

            if goals.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, contentIndent)
            } else {
                GoalSiblingRows(
                    goals: goals,
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

    private var sectionHeaderIndent: CGFloat {
        CGFloat(levelDepth) * 18 + 30
    }

    private var contentIndent: CGFloat {
        CGFloat(levelDepth) * 18 + 48
    }
}
