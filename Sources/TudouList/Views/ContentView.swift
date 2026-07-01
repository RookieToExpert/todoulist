import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("expandedGoalIdsByPlanList") private var persistedExpandedGoalIds = "{}"
    @AppStorage("isDetailPaneVisible") private var isDetailPaneVisible = true
    @StateObject private var store = PlanningStore()
    @State private var sidebarSelection: SidebarSelection?
    @State private var selectedGoalId: UUID?
    @State private var expandedGoalIdsByPlanList: [UUID: Set<UUID>] = [:]
    @State private var windowWidth: CGFloat = 0
    @State private var hostingWindow: NSWindow?
    @State private var inspectorLayoutRevision = 0
    @State private var newPlanName = ""
    @State private var showingNewPlan = false
    @State private var renamingPlan: PlanList?
    @State private var renamePlanName = ""
    @State private var deletingPlan: PlanList?

    private enum LayoutMetrics {
        static let sidebarMinWidth: CGFloat = 240
        static let sidebarIdealWidth: CGFloat = 260
        static let sidebarMaxWidth: CGFloat = 320
        static let primaryMinWidth: CGFloat = 620
        static let primaryIdealWidth: CGFloat = 980
        static let inspectorMinWidth: CGFloat = 420
        static let inspectorIdealWidth: CGFloat = 420
        static let inspectorMaxWidth: CGFloat = 460
        static let splitDividerAllowance: CGFloat = 24
        static let twoColumnMinWidth = sidebarMinWidth + primaryMinWidth
        static let threeColumnMinWidth = twoColumnMinWidth + inspectorMinWidth + splitDividerAllowance
    }

    private var selectedPlan: PlanList? {
        guard case let .planList(planId) = sidebarSelection else { return nil }
        return store.planLists.first { $0.id == planId }
    }

    private var selectedOverview: OverviewKind? {
        guard case let .overview(kind) = sidebarSelection else { return nil }
        return kind
    }

    var body: some View {
        GeometryReader { proxy in
            mainSplitView
                .background(WindowAccessor(window: $hostingWindow))
                .onAppear {
                    updateWindowWidth(proxy.size.width)
                }
                .onChange(of: proxy.size.width) { _, width in
                    updateWindowWidth(width)
                }
        }
            .frame(minWidth: LayoutMetrics.twoColumnMinWidth, minHeight: 620)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleDetailPane()
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                    .help(isDetailPaneVisible ? "隐藏详情面板" : "显示详情面板")
                }
            }
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
            .alert("重命名计划表", isPresented: isRenamingPlanPresented) {
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
                isPresented: isDeletingPlanPresented,
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    if let deletingPlan {
                        store.deletePlanList(deletingPlan)
                        let deletingPlanId = deletingPlan.id
                        expandedGoalIdsByPlanList[deletingPlanId] = nil
                        persistExpandedGoalIds()

                        switch sidebarSelection {
                        case let .planList(planId) where planId == deletingPlanId:
                            sidebarSelection = store.planLists.first.map { .planList($0.id) } ?? .overview(.todayFocus)
                        default:
                            break
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

    private var mainSplitView: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            primaryContentView
                .id(inspectorLayoutRevision)
                .navigationSplitViewColumnWidth(
                    min: LayoutMetrics.primaryMinWidth,
                    ideal: LayoutMetrics.primaryIdealWidth
                )
                .inspector(isPresented: inspectorVisibilityBinding) {
                    GoalDetailView(goalID: selectedGoalId, store: store)
                        .inspectorColumnWidth(
                            min: LayoutMetrics.inspectorMinWidth,
                            ideal: LayoutMetrics.inspectorIdealWidth,
                            max: LayoutMetrics.inspectorMaxWidth
                        )
                }
        }
    }

    private var sidebarView: some View {
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
        .navigationSplitViewColumnWidth(
            min: LayoutMetrics.sidebarMinWidth,
            ideal: LayoutMetrics.sidebarIdealWidth,
            max: LayoutMetrics.sidebarMaxWidth
        )
    }

    @ViewBuilder
    private var primaryContentView: some View {
        if let selectedOverview {
            OverviewContentView(
                kind: selectedOverview,
                selectedGoalId: $selectedGoalId,
                store: store
            )
        } else {
            GoalBoardView(
                plan: selectedPlan,
                selectedGoalId: $selectedGoalId,
                expandedGoalIds: expandedGoalIdsBinding(for: selectedPlan?.id),
                store: store
            )
        }
    }

    private var isRenamingPlanPresented: Binding<Bool> {
        Binding(
            get: { renamingPlan != nil },
            set: { if !$0 { renamingPlan = nil } }
        )
    }

    private var isDeletingPlanPresented: Binding<Bool> {
        Binding(
            get: { deletingPlan != nil },
            set: { if !$0 { deletingPlan = nil } }
        )
    }

    private var inspectorVisibilityBinding: Binding<Bool> {
        Binding(
            get: { isDetailPaneVisible },
            set: { isVisible in
                isDetailPaneVisible = isVisible
                if !isVisible {
                    DispatchQueue.main.async {
                        inspectorLayoutRevision += 1
                    }
                }
            }
        )
    }

    private func updateWindowWidth(_ width: CGFloat) {
        windowWidth = width
        if width < LayoutMetrics.threeColumnMinWidth, isDetailPaneVisible {
            // Passive resize: keep the readable two-column layout by dropping the inspector first.
            isDetailPaneVisible = false
        }
    }

    private func toggleDetailPane() {
        if isDetailPaneVisible {
            isDetailPaneVisible = false
        } else if windowWidth == 0 || windowWidth >= LayoutMetrics.threeColumnMinWidth {
            isDetailPaneVisible = true
        } else {
            expandWindowForDetailPane()
            DispatchQueue.main.async {
                isDetailPaneVisible = true
            }
        }
    }

    private func expandWindowForDetailPane() {
        guard let hostingWindow else { return }

        let contentToFrameWidth = hostingWindow.frame.width - windowWidth
        let targetFrameWidth = LayoutMetrics.threeColumnMinWidth + max(contentToFrameWidth, 0)
        guard hostingWindow.frame.width < targetFrameWidth else { return }

        var frame = hostingWindow.frame
        let widthDeficit = targetFrameWidth - frame.width
        frame.size.width = targetFrameWidth
        frame.origin.x -= widthDeficit
        hostingWindow.setFrame(frame, display: true, animate: true)
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

private struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            window = nsView.window
        }
    }
}
