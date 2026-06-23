import SwiftUI

struct PlanSidebarView: View {
    let planLists: [PlanList]
    @Binding var selection: SidebarSelection?
    let onAdd: () -> Void
    let onRename: (PlanList) -> Void
    let onDelete: (PlanList) -> Void

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section("总览") {
                    ForEach(OverviewKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.systemImage)
                            .tag(SidebarSelection.overview(kind))
                    }
                }

                Section("计划表") {
                    ForEach(planLists) { plan in
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plan.name)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                if !plan.descriptionText.isEmpty {
                                    Text(plan.descriptionText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        } icon: {
                            Image(systemName: "rectangle.stack")
                                .foregroundStyle(.secondary)
                        }
                        .tag(SidebarSelection.planList(plan.id))
                        .contextMenu {
                            Button("重命名") {
                                onRename(plan)
                            }
                            Button("删除", role: .destructive) {
                                onDelete(plan)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            Button {
                onAdd()
            } label: {
                Label("新建计划表", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    onAdd()
                } label: {
                    Label("新建计划表", systemImage: "plus")
                }
            }
        }
    }
}
