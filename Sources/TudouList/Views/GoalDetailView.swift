import SwiftUI

struct GoalDetailView: View {
    let goalID: UUID?
    @ObservedObject var store: PlanningStore

    var body: some View {
        Group {
            if let goalID, store.goal(id: goalID) != nil {
                GoalEditor(goalID: goalID, store: store)
            } else {
                EmptyStateView(
                    systemImage: "square.and.pencil",
                    title: "选择目标查看详情",
                    message: "在右侧编辑标题、备注、完成状态和加急标记。"
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct GoalEditor: View {
    let goalID: UUID
    @ObservedObject var store: PlanningStore
    @AppStorage("goalDetailMetadataExpanded") private var isMetadataExpanded = true

    private var goal: Goal? {
        store.goal(id: goalID)
    }

    var body: some View {
        Form {
            Section {
                TextField("标题", text: titleBinding, axis: .vertical)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1...3)

                TextEditor(text: noteBinding)
                    .font(.body)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
            } header: {
                Text(goal?.periodDisplayName ?? "目标")
            }

            Section("状态") {
                Toggle("已完成", isOn: Binding(
                    get: { goal?.isCompleted ?? false },
                    set: { value in
                        store.flushSave()
                        if let goal {
                            store.setCompleted(goal, isCompleted: value)
                        }
                    }
                ))

                if goal?.canUseUrgent == true {
                    Toggle("加急", isOn: Binding(
                        get: { goal?.isUrgent ?? false },
                        set: { _ in
                            store.flushSave()
                            if let goal {
                                store.toggleUrgent(goal)
                            }
                        }
                    ))
                }

                if let completedAt = goal?.completedAt {
                    LabeledContent("完成时间") {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("计划") {
                Toggle("设置截止时间", isOn: dueDateEnabledBinding)

                if goal?.dueDate != nil {
                    DatePicker(
                        "截止时间",
                        selection: dueDateBinding,
                        displayedComponents: [.date]
                    )

                    Button("清除截止时间", role: .destructive) {
                        store.updateDueDate(id: goalID, dueDate: nil, flush: true)
                    }
                }
            }

            Section {
                Button {
                    isMetadataExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isMetadataExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("元信息")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isMetadataExpanded, let goal {
                    LabeledContent("创建时间") {
                        Text(goal.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("更新时间") {
                        Text(goal.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
        .onDisappear {
            store.flushSave()
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { goal?.title ?? "" },
            set: { store.updateGoal(id: goalID, title: $0) }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { goal?.note ?? "" },
            set: { store.updateGoal(id: goalID, note: $0) }
        )
    }

    private var dueDateEnabledBinding: Binding<Bool> {
        Binding(
            get: { goal?.dueDate != nil },
            set: { isEnabled in
                if isEnabled {
                    store.updateDueDate(id: goalID, dueDate: goal?.dueDate ?? .now, flush: true)
                } else {
                    store.updateDueDate(id: goalID, dueDate: nil, flush: true)
                }
            }
        )
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { goal?.dueDate ?? .now },
            set: { store.updateDueDate(id: goalID, dueDate: $0) }
        )
    }
}
