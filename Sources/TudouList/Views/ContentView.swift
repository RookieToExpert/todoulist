import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("expandedGoalIdsByPlanList") private var persistedExpandedGoalIds = "{}"
    @StateObject private var store = PlanningStore()
    @State private var sidebarSelection: SidebarSelection?
    @State private var selectedGoalId: UUID?
    @State private var expandedGoalIdsByPlanList: [UUID: Set<UUID>] = [:]
    @State private var newPlanName = ""
    @State private var showingNewPlan = false
    @State private var renamingPlan: PlanList?
    @State private var renamePlanName = ""
    @State private var deletingPlan: PlanList?

    private var selectedPlan: PlanList? {
        guard case let .planList(planId) = sidebarSelection else { return nil }
        return store.planLists.first { $0.id == planId }
    }

    private var selectedOverview: OverviewKind? {
        guard case let .overview(kind) = sidebarSelection else { return nil }
        return kind
    }

    var body: some View {
        NavigationSplitView {
            PlanSidebarView(
                planLists: store.planLists,
                selection: $sidebarSelection,
                onAdd: {
                    newPlanName = ""
                    showingNewPlan = true
                },
                onRename: { plan in
                    renamingPlan = plan
                    renamePlanName = plan.name
                },
                onDelete: { plan in
                    deletingPlan = plan
                }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            if let selectedOverview {
                OverviewContentView(
                    kind: selectedOverview,
                    selectedGoalId: $selectedGoalId,
                    store: store
                )
                .navigationSplitViewColumnWidth(min: 460, ideal: 620)
            } else {
                GoalBoardView(
                    plan: selectedPlan,
                    selectedGoalId: $selectedGoalId,
                    expandedGoalIds: expandedGoalIdsBinding(for: selectedPlan?.id),
                    store: store
                )
                .navigationSplitViewColumnWidth(min: 460, ideal: 620)
            }
        } detail: {
            GoalDetailView(goalID: selectedGoalId, store: store)
                .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 460)
        }
        .frame(minWidth: 980, minHeight: 620)
        .onAppear {
            expandedGoalIdsByPlanList = decodeExpandedGoalIds(from: persistedExpandedGoalIds)
            sidebarSelection = sidebarSelection ?? .overview(.todayFocus)
        }
        .onChange(of: store.planLists.map(\.id)) { _, ids in
            if sidebarSelection == nil {
                sidebarSelection = .overview(.todayFocus)
            } else if case let .planList(planId) = sidebarSelection, !ids.contains(planId) {
                sidebarSelection = ids.first.map(SidebarSelection.planList) ?? .overview(.todayFocus)
                selectedGoalId = nil
            }
        }
        .onChange(of: sidebarSelection) {
            store.flushSave()
            selectedGoalId = nil
        }
        .onChange(of: selectedGoalId) {
            store.flushSave()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                store.flushSave()
            }
        }
        .alert("新建计划表", isPresented: $showingNewPlan) {
            TextField("计划表名称", text: $newPlanName)
            Button("创建") {
                let plan = store.createPlanList(name: newPlanName)
                sidebarSelection = .planList(plan.id)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("例如：学习计划、工作冲刺、长期目标。")
        }
        .alert("重命名计划表", isPresented: Binding(
            get: { renamingPlan != nil },
            set: { if !$0 { renamingPlan = nil } }
        )) {
            TextField("计划表名称", text: $renamePlanName)
            Button("保存") {
                if let renamingPlan {
                    store.updatePlanList(renamingPlan, name: renamePlanName)
                }
                renamingPlan = nil
            }
            Button("取消", role: .cancel) {
                renamingPlan = nil
            }
        }
        .confirmationDialog(
            "删除计划表？",
            isPresented: Binding(
                get: { deletingPlan != nil },
                set: { if !$0 { deletingPlan = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let deletingPlan {
                    store.deletePlanList(deletingPlan)
                    expandedGoalIdsByPlanList[deletingPlan.id] = nil
                    persistExpandedGoalIds()
                    if sidebarSelection == .planList(deletingPlan.id) {
                        sidebarSelection = store.planLists.first.map { .planList($0.id) } ?? .overview(.todayFocus)
                    }
                    selectedGoalId = nil
                }
                deletingPlan = nil
            }
            Button("取消", role: .cancel) {
                deletingPlan = nil
            }
        } message: {
            Text("该计划表中的所有目标都会被删除。")
        }
    }
    private func expandedGoalIdsBinding(for planId: UUID?) -> Binding<Set<UUID>> {
        Binding(
            get: {
                guard let planId else { return [] }
                return expandedGoalIdsByPlanList[planId] ?? []
            },
            set: { newValue in
                guard let planId else { return }
                expandedGoalIdsByPlanList[planId] = newValue
                persistExpandedGoalIds()
            }
        )
    }

    private func persistExpandedGoalIds() {
        let snapshot = expandedGoalIdsByPlanList.reduce(into: [String: [String]]()) { result, item in
            result[item.key.uuidString] = item.value.map(\.uuidString).sorted()
        }
        guard let data = try? JSONEncoder().encode(snapshot),
              let value = String(data: data, encoding: .utf8)
        else { return }
        persistedExpandedGoalIds = value
    }

    private func decodeExpandedGoalIds(from value: String) -> [UUID: Set<UUID>] {
        guard let data = value.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }

        return snapshot.reduce(into: [UUID: Set<UUID>]()) { result, item in
            guard let planId = UUID(uuidString: item.key) else { return }
            let goalIds = item.value.compactMap(UUID.init(uuidString:))
            result[planId] = Set(goalIds)
        }
    }

}
