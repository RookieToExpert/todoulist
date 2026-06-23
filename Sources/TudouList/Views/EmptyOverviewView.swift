import SwiftUI

struct EmptyOverviewView: View {
    let kind: OverviewKind

    var body: some View {
        EmptyStateView(
            systemImage: kind.systemImage,
            title: kind.emptyTitle,
            message: kind.emptyMessage
        )
    }
}
