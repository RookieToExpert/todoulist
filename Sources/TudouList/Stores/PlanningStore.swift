import Combine
import Foundation

@MainActor
final class PlanningStore: ObservableObject {
    @Published private(set) var planLists: [PlanList] = []
    @Published private(set) var goals: [Goal] = []

    private let storeURL: URL
    private let saveDebounceDelay: TimeInterval = 0.35
    private var pendingSaveWorkItem: DispatchWorkItem?

    init(storeURL: URL? = nil) {
        self.storeURL = storeURL ?? Self.defaultStoreURL()
        load()
    }

    func createPlanList(name: String, description: String = "") -> PlanList {
        let plan = PlanList(name: cleaned(name, fallback: "新的计划表"), descriptionText: description)
        planLists.append(plan)
        saveNow()
        return plan
    }

    func updatePlanList(_ plan: PlanList, name: String? = nil, description: String? = nil) {
        guard let index = planLists.firstIndex(where: { $0.id == plan.id }) else { return }
        if let name {
            planLists[index].name = cleaned(name, fallback: planLists[index].name)
        }
        if let description {
            planLists[index].descriptionText = description
        }
        planLists[index].updatedAt = .now
        saveNow()
    }

    func deletePlanList(_ plan: PlanList) {
        goals.removeAll { $0.planListId == plan.id }
        planLists.removeAll { $0.id == plan.id }
        saveNow()
    }

    func allowedChildLevels(for parent: Goal?) -> [GoalLevel] {
        guard let parent else { return [.year] }
        switch parent.level {
        case .year:
            return [.month]
        case .month:
            return [.week, .day]
        case .week:
            return [.day]
        case .day:
            return []
        }
    }

    func createGoal(
        planListId: UUID,
        parent: Goal?,
        level requestedLevel: GoalLevel? = nil,
        title: String? = nil
    ) -> Goal? {
        let allowedLevels = allowedChildLevels(for: parent)
        guard let level = requestedLevel ?? allowedLevels.first,
              allowedLevels.contains(level)
        else { return nil }

        let now = Date()
        let siblings = goals.filter {
            $0.planListId == planListId && $0.parentId == parent?.id && $0.level == level
        }
        let nextOrder = (siblings.map(\.sortOrder).max() ?? 0) + 1
        let fallbackTitle = defaultTitle(for: level, date: now)
        let goal = Goal(
            planListId: planListId,
            parentId: parent?.id,
            title: cleaned(title ?? fallbackTitle, fallback: fallbackTitle),
            level: level,
            createdAt: now,
            updatedAt: now,
            sortOrder: nextOrder
        )
        goals.append(goal)
        if let parent, let parentIndex = goals.firstIndex(where: { $0.id == parent.id }) {
            goals[parentIndex].updatedAt = .now
        }
        saveNow()
        return goal
    }

    func updateGoal(_ goal: Goal, title: String? = nil, note: String? = nil) {
        updateGoal(id: goal.id, title: title, note: note)
    }

    func updateGoal(id: UUID, title: String? = nil, note: String? = nil, flush: Bool = false) {
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        var updatedGoal = goals[index]
        var didChange = false
        if let title {
            let nextTitle = cleaned(title, fallback: updatedGoal.title)
            if updatedGoal.title != nextTitle {
                updatedGoal.title = nextTitle
                didChange = true
            }
        }
        if let note, updatedGoal.note != note {
            updatedGoal.note = note
            didChange = true
        }
        guard didChange else { return }
        updatedGoal.updatedAt = .now
        goals[index] = updatedGoal
        flush ? saveNow() : scheduleSave()
    }

    func setCompleted(_ goal: Goal, isCompleted: Bool) {
        if isCompleted {
            completeGoalAndDescendants(goal.id, completedAt: .now)
        } else {
            // TODO: Offer an option to also uncomplete descendants when reopening a parent goal.
            uncompleteGoalOnly(goal.id)
        }
        saveNow()
    }

    func toggleUrgent(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index].isUrgent.toggle()
        goals[index].updatedAt = .now
        saveNow()
    }

    func deleteGoal(_ goal: Goal) {
        let deleteIds = Set(([goal] + descendantGoals(of: goal.id, in: goals)).map(\.id))
        goals.removeAll { deleteIds.contains($0.id) }
        saveNow()
    }

    func goal(id: UUID?) -> Goal? {
        guard let id else { return nil }
        return goals.first { $0.id == id }
    }

    func sortedGoals(_ goals: [Goal]) -> [Goal] {
        goals.sorted(by: goalDisplaySort)
    }

    // TODO: Add same-level drag reordering by updating sortOrder values from a drop delegate.
    func orderedGoals(planListId: UUID, parentId: UUID?) -> [Goal] {
        sortedGoals(
            goals.filter { $0.planListId == planListId && $0.parentId == parentId }
        )
    }

    func hasChildren(_ goal: Goal) -> Bool {
        goals.contains { $0.parentId == goal.id }
    }

    func goalsForOverview(_ kind: OverviewKind) -> [Goal] {
        switch kind {
        case .todayFocus:
            // TODO: Add scheduledDate/dueDate later for a true today view.
            let urgentGoals = goals
                .filter { !$0.isCompleted && $0.isUrgent }
                .sorted(by: overviewRecentSort)
            let urgentIds = Set(urgentGoals.map(\.id))
            let recentGoals = goals
                .filter { !$0.isCompleted && !urgentIds.contains($0.id) }
                .sorted(by: overviewRecentSort)
                .prefix(10)
            return urgentGoals + Array(recentGoals)
        case .thisWeek:
            let weekGoalIds = Set(goals.filter { $0.level == .week }.map(\.id))
            return sortedGoals(
                goals.filter { goal in
                    goal.level == .week || goal.parentId.map { weekGoalIds.contains($0) } == true
                }
            )
        case .urgent:
            return sortedGoals(goals.filter(\.isUrgent))
        case .all:
            return sortedGoals(goals)
        case .completed:
            return goals
                .filter(\.isCompleted)
                .sorted(by: completedOverviewSort)
        }
    }

    func overviewStats(for kind: OverviewKind) -> OverviewStats {
        let visibleGoals = goalsForOverview(kind)
        return OverviewStats(
            incompleteCount: visibleGoals.filter { !$0.isCompleted }.count,
            urgentCount: visibleGoals.filter(\.isUrgent).count,
            completedCount: visibleGoals.filter(\.isCompleted).count,
            planListCount: planLists.count
        )
    }

    func planListName(for goal: Goal) -> String {
        planLists.first { $0.id == goal.planListId }?.name ?? "未知计划表"
    }

    func goalPath(for goal: Goal) -> String {
        var path: [String] = []
        var currentParentId = goal.parentId
        var visitedIds = Set<UUID>()

        while let parentId = currentParentId, !visitedIds.contains(parentId) {
            visitedIds.insert(parentId)
            guard let parent = goals.first(where: { $0.id == parentId }) else { break }
            path.insert(parent.title, at: 0)
            currentParentId = parent.parentId
        }

        let planName = planListName(for: goal)
        return ([planName] + path).joined(separator: " / ")
    }

    private func goalDisplaySort(_ lhs: Goal, _ rhs: Goal) -> Bool {
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted && rhs.isCompleted }
        if lhs.isUrgent != rhs.isUrgent { return lhs.isUrgent && !rhs.isUrgent }
        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        return lhs.createdAt < rhs.createdAt
    }

    private func overviewRecentSort(_ lhs: Goal, _ rhs: Goal) -> Bool {
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted && rhs.isCompleted }
        if lhs.isUrgent != rhs.isUrgent { return lhs.isUrgent && !rhs.isUrgent }
        if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
        return lhs.createdAt > rhs.createdAt
    }

    private func completedOverviewSort(_ lhs: Goal, _ rhs: Goal) -> Bool {
        switch (lhs.completedAt, rhs.completedAt) {
        case let (lhsDate?, rhsDate?):
            if lhsDate != rhsDate { return lhsDate > rhsDate }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }
        return lhs.updatedAt > rhs.updatedAt
    }

    private func completeGoalAndDescendants(_ goalId: UUID, completedAt: Date) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }

        if !goals[index].isCompleted {
            goals[index].isCompleted = true
            goals[index].completedAt = completedAt
            goals[index].updatedAt = completedAt
        }

        let childIds = goals
            .filter { $0.parentId == goalId }
            .map(\.id)

        for childId in childIds {
            completeGoalAndDescendants(childId, completedAt: completedAt)
        }
    }

    private func uncompleteGoalOnly(_ goalId: UUID) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        goals[index].isCompleted = false
        goals[index].completedAt = nil
        goals[index].updatedAt = .now
    }

    private func descendantGoals(of parentId: UUID, in goals: [Goal]) -> [Goal] {
        let children = goals.filter { $0.parentId == parentId }
        return children + children.flatMap { descendantGoals(of: $0.id, in: goals) }
    }

    private func cleaned(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func defaultTitle(for level: GoalLevel, date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1

        switch level {
        case .year:
            return "\(year) 年目标"
        case .month:
            return "\(month) 月目标"
        case .week:
            let weekOfMonth = ((day - 1) / 7) + 1
            return "第 \(weekOfMonth) 周目标"
        case .day:
            return "\(month) 月 \(day) 日目标"
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storeURL)
            let snapshot = try JSONDecoder.tudou.decode(StoreSnapshot.self, from: data)
            planLists = snapshot.planLists
            goals = snapshot.goals
        } catch CocoaError.fileReadNoSuchFile {
            planLists = []
            goals = []
        } catch {
            assertionFailure("JSON store load failed: \(error)")
            planLists = []
            goals = []
        }
    }

    func flushSave() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        saveNow()
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.saveNow()
            }
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceDelay, execute: workItem)
    }

    private func saveNow() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let snapshot = StoreSnapshot(planLists: planLists, goals: goals)
            let data = try JSONEncoder.tudou.encode(snapshot)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            assertionFailure("JSON store save failed: \(error)")
        }
    }

    private static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appending(path: "TudouList", directoryHint: .isDirectory)
            .appending(path: "store.json")
    }
}

private struct StoreSnapshot: Codable {
    var planLists: [PlanList]
    var goals: [Goal]
}

private extension JSONEncoder {
    static var tudou: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var tudou: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
