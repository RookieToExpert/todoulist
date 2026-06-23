import Foundation

struct PlanList: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var descriptionText: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
