import Foundation

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID
    var planListId: UUID
    var parentId: UUID?
    var title: String
    var note: String
    var level: GoalLevel
    var isCompleted: Bool
    var completedAt: Date?
    var isUrgent: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Double

    init(
        id: UUID = UUID(),
        planListId: UUID,
        parentId: UUID? = nil,
        title: String,
        note: String = "",
        level: GoalLevel,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isUrgent: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sortOrder: Double
    ) {
        self.id = id
        self.planListId = planListId
        self.parentId = parentId
        self.title = title
        self.note = note
        self.level = level
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isUrgent = isUrgent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}

extension Goal {
    var periodDisplayName: String {
        switch level {
        case .year:
            return "\(periodComponents.year) 年"
        case .month:
            return "\(periodComponents.month) 月"
        case .week:
            return "第 \(periodComponents.weekOfMonth) 周"
        case .day:
            return String(format: "%02d-%02d", periodComponents.month, periodComponents.day)
        }
    }

    var periodDisplayKey: String {
        switch level {
        case .year:
            return "year-\(periodComponents.year)"
        case .month:
            return String(format: "month-%04d-%02d", periodComponents.year, periodComponents.month)
        case .week:
            return String(format: "week-%04d-%02d-%d", periodComponents.year, periodComponents.month, periodComponents.weekOfMonth)
        case .day:
            return String(format: "day-%04d-%02d-%02d", periodComponents.year, periodComponents.month, periodComponents.day)
        }
    }

    private var periodComponents: (year: Int, month: Int, day: Int, weekOfMonth: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: createdAt)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1
        let weekOfMonth = ((day - 1) / 7) + 1
        return (year, month, day, weekOfMonth)
    }
}
