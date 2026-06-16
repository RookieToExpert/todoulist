import SwiftUI

struct OverviewContentView: View {
    let kind: OverviewKind
    @Binding var selectedGoalId: UUID?
    @ObservedObject var store: PlanningStore
    @State private var levelFilter: GoalLevelFilter = .all

    private var allOverviewGoals: [Goal] {
        store.goalsForOverview(kind)
    }

    private var goals: [Goal] {
        allOverviewGoals.filter { levelFilter.includes($0) }
    }

    private var stats: OverviewStats {
        OverviewStats(
            incompleteCount: goals.filter { !$0.isCompleted }.count,
            urgentCount: goals.filter(\.isUrgent).count,
            completedCount: goals.filter(\.isCompleted).count,
            planListCount: store.planLists.count
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            overviewHeader
            Divider()

            if goals.isEmpty {
                EmptyOverviewView(kind: kind)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(goals) { goal in
                            OverviewGoalRowView(
                                goal: goal,
                                isSelected: selectedGoalId == goal.id,
                                store: store
                            ) {
                                selectedGoalId = goal.id
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
        .toolbar {
            ToolbarItem {
                Label("请进入具体计划表后新增目标", systemImage: "plus.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var overviewHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.title2.weight(.semibold))
                    Text(kind.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(alignment: .center) {
                OverviewStatsView(stats: stats)

                Picker("目标层级", selection: $levelFilter) {
                    ForEach(GoalLevelFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.regularMaterial)
    }

}
