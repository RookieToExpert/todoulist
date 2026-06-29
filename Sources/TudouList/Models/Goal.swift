import Foundation

enum GoalKind: String, Codable, CaseIterable, Identifiable {
    case objective
    case action

    var id: String { rawValue }
}

enum ActionScope: String, Codable, CaseIterable, Identifiable {
    case none
    case thisWeek
    case today
    case later

    var id: String { rawValue }
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID
    var planListId: UUID
    var parentId: UUID?
    var title: String
    var note: String
    var level: GoalLevel
    var kind: GoalKind
    var actionScope: ActionScope
    var dueDate: Date?
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
        kind: GoalKind = .objective,
        actionScope: ActionScope = .none,
        dueDate: Date? = nil,
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
        self.kind = kind
        self.actionScope = actionScope
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isUrgent = isUrgent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case planListId
        case parentId
        case title
        case note
        case level
        case kind
        case actionScope
        case dueDate
        case isCompleted
        case completedAt
        case isUrgent
        case createdAt
        case updatedAt
        case sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        planListId = try container.decode(UUID.self, forKey: .planListId)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        title = try container.decode(String.self, forKey: .title)
        note = try container.decode(String.self, forKey: .note)
        level = try container.decode(GoalLevel.self, forKey: .level)

        let legacyValues = Self.legacyKindAndScope(for: level, title: title)
        kind = try container.decodeIfPresent(GoalKind.self, forKey: .kind) ?? legacyValues.kind
        actionScope = try container.decodeIfPresent(ActionScope.self, forKey: .actionScope) ?? legacyValues.actionScope
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)

        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        isUrgent = try container.decode(Bool.self, forKey: .isUrgent)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sortOrder = try container.decode(Double.self, forKey: .sortOrder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(planListId, forKey: .planListId)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(title, forKey: .title)
        try container.encode(note, forKey: .note)
        try container.encode(level, forKey: .level)
        try container.encode(kind, forKey: .kind)
        try container.encode(actionScope, forKey: .actionScope)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(isUrgent, forKey: .isUrgent)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(sortOrder, forKey: .sortOrder)
    }
}

extension Goal {
    var effectiveKind: GoalKind {
        kind
    }

    var effectiveActionScope: ActionScope {
        actionScope
    }

    var semanticDisplayName: String {
        switch effectiveKind {
        case .objective:
            return level == .year ? "长期目标" : "阶段目标"
        case .action:
            switch effectiveActionScope {
            case .none:
                return "行动"
            case .thisWeek:
                return "待分配"
            case .today:
                return "今日必须"
            case .later:
                return "待分配"
            }
        }
    }

    var isLegacyWeekContainer: Bool {
        Self.isLegacyWeekContainerTitle(title, level: level)
    }

    static func legacyKindAndScope(for level: GoalLevel, title: String) -> (kind: GoalKind, actionScope: ActionScope) {
        switch level {
        case .year, .month:
            return (.objective, .none)
        case .week:
            if isLegacyWeekContainerTitle(title, level: level) {
                return (.objective, .none)
            }
            return (.action, .thisWeek)
        case .day:
            return (.action, .today)
        }
    }

    private static func isLegacyWeekContainerTitle(_ title: String, level: GoalLevel) -> Bool {
        guard level == .week else { return false }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = trimmed.range(of: #"^第\s*\d+\s*周$"#, options: .regularExpression) else {
            return false
        }

        return match.lowerBound == trimmed.startIndex && match.upperBound == trimmed.endIndex
    }

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
