import SwiftUI

struct GoalBoardView: View {
    let plan: PlanList?
    @Binding var selectedGoalId: UUID?
    @ObservedObject var store: PlanningStore

    @State private var expandedGoalIds: Set<UUID> = []
    @State private var deletingGoal: Goal?

    private var planGoals: [Goal] {
        guard let plan else { return [] }
        return store.goals.filter { $0.planListId == plan.id }
    }

    private var selectedGoal: Goal? {
        store.goal(id: selectedGoalId)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let plan {
                header(for: plan)
                Divider()
                if planGoals.isEmpty {
                    EmptyStateView(
                        systemImage: "target",
                        title: "从一个年目标开始",
                        message: "建立计划表的第一层目标，再逐步拆到月、周、日。"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            GoalSiblingRows(
                                goals: store.orderedGoals(planListId: plan.id, parentId: nil),
                                planListId: plan.id,
                                levelDepth: 0,
                                selectedGoalId: $selectedGoalId,
                                expandedGoalIds: $expandedGoalIds,
                                store: store,
                                onDelete: { deletingGoal = $0 }
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                }
            } else {
                EmptyStateView(
                    systemImage: "sidebar.left",
                    title: "选择一个计划表开始规划",
                    message: "左侧可以创建短期目标、长期目标、工作计划或学习计划。"
                )
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    addYearGoal()
                } label: {
                    Label("新增年目标", systemImage: "plus.circle")
                }
                .disabled(plan == nil)

                Button {
                    addChildGoal()
                } label: {
                    Label("新增下一级", systemImage: "arrow.down.right.circle")
                }
                .disabled(selectedGoal.map { store.allowedChildLevels(for: $0).isEmpty } ?? true)
            }
        }
        .confirmationDialog(
            "删除目标？",
            isPresented: Binding(
                get: { deletingGoal != nil },
                set: { if !$0 { deletingGoal = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let deletingGoal {
                    store.deleteGoal(deletingGoal)
                    if selectedGoalId == deletingGoal.id {
                        selectedGoalId = nil
                    }
                }
                deletingGoal = nil
            }
            Button("取消", role: .cancel) {
                deletingGoal = nil
            }
        } message: {
            Text("该目标下的所有子目标也会被删除。")
        }
    }

    private func header(for plan: PlanList) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.title2.weight(.semibold))
                Text(plan.descriptionText.isEmpty ? "计划表" : plan.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                addYearGoal()
            } label: {
                Label("年目标", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.regularMaterial)
    }

    private func addYearGoal() {
        guard let plan else { return }
        if let goal = store.createGoal(planListId: plan.id, parent: nil, level: .year) {
            selectedGoalId = goal.id
            expandedGoalIds.insert(goal.id)
        }
    }

    private func addChildGoal() {
        guard let plan, let selectedGoal else { return }
        if let goal = store.createGoal(planListId: plan.id, parent: selectedGoal) {
            selectedGoalId = goal.id
            expandedGoalIds.insert(selectedGoal.id)
        }
    }
}
