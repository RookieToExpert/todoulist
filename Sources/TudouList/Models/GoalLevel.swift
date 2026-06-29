import Foundation

enum GoalLevel: String, Codable, CaseIterable, Identifiable {
    case year
    case month
    case week
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .year: "Year"
        case .month: "Month"
        case .week: "Week"
        case .day: "Day"
        }
    }

    var displayName: String {
        switch self {
        case .year: "长期目标"
        case .month: "阶段目标"
        case .week: "本周行动"
        case .day: "今日必须"
        }
    }

    var childLevel: GoalLevel? {
        switch self {
        case .year: .month
        case .month: .week
        case .week: .day
        case .day: nil
        }
    }

    var accentSymbol: String {
        switch self {
        case .year: "calendar"
        case .month: "calendar.badge.clock"
        case .week: "calendar.day.timeline.left"
        case .day: "checklist"
        }
    }
}
