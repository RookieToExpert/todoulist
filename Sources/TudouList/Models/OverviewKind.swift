import Foundation

enum OverviewKind: String, CaseIterable, Identifiable, Hashable {
    case todayFocus
    case thisWeek
    case urgent
    case all
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayFocus: "今日重点"
        case .thisWeek: "本周目标"
        case .urgent: "加急"
        case .all: "全部目标"
        case .completed: "已完成"
        }
    }

    var subtitle: String {
        switch self {
        case .todayFocus: "集中查看当前最应该处理的目标"
        case .thisWeek: "查看所有计划表里的周目标"
        case .urgent: "所有已标记加急的目标"
        case .all: "跨计划表查看所有目标"
        case .completed: "查看最近完成的目标"
        }
    }

    var systemImage: String {
        switch self {
        case .todayFocus: "sun.max"
        case .thisWeek: "calendar.day.timeline.left"
        case .urgent: "flag"
        case .all: "tray.full"
        case .completed: "checkmark.circle"
        }
    }

    var emptyTitle: String {
        switch self {
        case .todayFocus: "暂无今日重点"
        case .thisWeek: "暂无本周目标"
        case .urgent: "暂无加急目标"
        case .all: "暂无目标"
        case .completed: "暂无已完成目标"
        }
    }

    var emptyMessage: String {
        switch self {
        case .todayFocus: "可以把重要目标标记为加急，它们会出现在这里。"
        case .thisWeek: "创建周目标后，它们会集中显示在这里。"
        case .urgent: "点击目标右侧的小旗帜即可标记加急。"
        case .all: "进入某个计划表，创建你的第一个目标。"
        case .completed: "完成目标后，它们会按时间出现在这里。"
        }
    }
}
