import Foundation

enum GoalLevelFilter: String, CaseIterable, Identifiable {
    case all
    case actionable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .actionable:
            return "仅行动"
        }
    }

    func includes(_ goal: Goal) -> Bool {
        switch self {
        case .all:
            return true
        case .actionable:
            return goal.effectiveKind == .action
        }
    }
}
