import SwiftUI

struct OverviewStatsView: View {
    let stats: OverviewStats

    var body: some View {
        HStack(spacing: 8) {
            statCard(title: "未完成", value: stats.incompleteCount, systemImage: "circle")
            statCard(title: "加急", value: stats.urgentCount, systemImage: "flag")
            statCard(title: "已完成", value: stats.completedCount, systemImage: "checkmark.circle")
            statCard(title: "计划表", value: stats.planListCount, systemImage: "rectangle.stack")
        }
    }

    private func statCard(title: String, value: Int, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.callout.weight(.semibold))
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        }
    }
}
