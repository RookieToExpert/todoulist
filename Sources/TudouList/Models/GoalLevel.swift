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
        case .year: "年目标"
        case .month: "月目标"
        case .week: "周目标"
        case .day: "日目标"
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
