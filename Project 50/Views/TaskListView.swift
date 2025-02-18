import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var editingTask: Task?
    @State private var editingDescription: String = ""
    @State private var showingEditTip = false
    @AppStorage("hasShownEditTip") private var hasShownEditTip = false
    
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
        .tint(.yellow)
        .overlay {
            if showingEditTip {
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
            if !hasShownEditTip && viewModel.currentChallenge != nil {
                let calendar = Calendar.current
                if let challengeStartDate = viewModel.currentChallenge?.startDate,
                   let minutesSinceStart = calendar.dateComponents([.minute], from: challengeStartDate, to: Date()).minute,
                   minutesSinceStart < 1 {
                    showingEditTip = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showingEditTip = false
                            hasShownEditTip = true
                        }
                    }
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
    @AppStorage("hasShownEditTip") private var hasShownEditTip = false
    
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
                    hasShownEditTip = false // 重置提示状态，确保新挑战开始时会显示提示
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