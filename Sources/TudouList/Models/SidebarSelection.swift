import Foundation

enum SidebarSelection: Hashable {
    case overview(OverviewKind)
    case planList(UUID)
}
