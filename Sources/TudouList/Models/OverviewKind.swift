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
        case .thisWeek: "待分配"
        case .urgent: "加急"
        case .all: "全部目标"
        case .completed: "已完成"
        }
    }

    var subtitle: String {
        switch self {
        case .todayFocus: "只查看今天必须完成的行动"
        case .thisWeek: "集中查看还未安排到今日必须的行动"
        case .urgent: "今日必须中标记加急的行动"
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
        case .thisWeek: "暂无待分配"
        case .urgent: "暂无加急目标"
        case .all: "暂无目标"
        case .completed: "暂无已完成目标"
        }
    }

    var emptyMessage: String {
        switch self {
        case .todayFocus: "在阶段目标中添加今日必须后，它们会出现在这里。"
        case .thisWeek: "创建本周行动或待安排任务后，它们会显示在这里。"
        case .urgent: "在今日必须任务上标记加急后，它们会显示在这里。"
        case .all: "进入某个计划表，创建你的第一个目标。"
        case .completed: "完成目标后，它们会按时间出现在这里。"
        }
    }
}
