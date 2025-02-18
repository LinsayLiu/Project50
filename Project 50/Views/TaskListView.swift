import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var editingTask: Task?
    @State private var editingDescription: String = ""
    @State private var showingRestartAlert = false
    
    var body: some View {
        List {
            if let challenge = viewModel.currentChallenge {
                Section {
                    ForEach(challenge.tasks) { task in
                        TaskRow(task: task) {
                            viewModel.toggleTask(task)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                editingTask = task
                                editingDescription = task.description
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.yellow)
                        }
                    }
                } header: {
                    HStack {
                        Text("第\(challenge.currentDay)天")
                            .font(.headline)
                        Spacer()
                        Text("连续打卡\(challenge.consecutiveDays)天")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        showingRestartAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("重启挑战")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            } else {
                Section {
                    Button(action: {
                        viewModel.showingNewChallengeSheet = true
                    }) {
                        Label("开始新的挑战", systemImage: "plus.circle.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .navigationTitle("今日任务")
        .sheet(isPresented: $viewModel.showingNewChallengeSheet) {
            NewChallengeView(viewModel: viewModel)
        }
        .sheet(item: $editingTask) { task in
            NavigationStack {
                Form {
                    Section(header: Text("任务描述")) {
                        TextEditor(text: $editingDescription)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle(task.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            editingTask = nil
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            viewModel.updateTaskDescription(task, newDescription: editingDescription)
                            editingTask = nil
                        }
                    }
                }
            }
        }
        .alert("确认重启挑战", isPresented: $showingRestartAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                viewModel.resetChallenge()
                viewModel.showingNewChallengeSheet = true
            }
        } message: {
            Text("重启后将清除所有进度，确定要重新开始吗？")
        }
        .tint(.yellow)
        .overlay {
            if viewModel.shouldShowEditTip {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("右滑任务卡片可以修改任务内容")
                            .font(.subheadline)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.checkChallengeStatus()
        }
        .onChange(of: viewModel.shouldShowEditTip) { oldValue, newValue in
            if newValue {
                // 3秒后自动隐藏提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    viewModel.hideEditTip()
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: task.category.icon)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 8)
    }
}

struct NewChallengeView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTasks: Set<Task.TaskCategory> = Set(Task.TaskCategory.allCases)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("选择你的每日任务")) {
                    ForEach(Task.TaskCategory.allCases, id: \.self) { category in
                        if category != .custom {
                            Toggle(isOn: Binding(
                                get: { selectedTasks.contains(category) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedTasks.insert(category)
                                    } else {
                                        selectedTasks.remove(category)
                                    }
                                }
                            )) {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                            .tint(.yellow)
                        }
                    }
                }
            }
            .navigationTitle("新的挑战")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("开始") {
                    let tasks = Task.templates.filter { selectedTasks.contains($0.category) }
                    viewModel.startNewChallenge(with: tasks)
                    dismiss()
                }
                .disabled(selectedTasks.isEmpty)
            )
            .tint(.yellow)
        }
    }
}

#Preview {
    NavigationView {
        TaskListView(viewModel: ChallengeViewModel())
    }
} 