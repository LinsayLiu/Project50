import Foundation
import SwiftUI

class ChallengeViewModel: ObservableObject {
    @Published var currentChallenge: Challenge?
    @Published var showingNewChallengeSheet = false
    @Published var showingJournalSheet = false
    @Published var selectedDay: SelectedDay?
    
    private let userDefaults = UserDefaults.standard
    private let challengeKey = "current_challenge"
    
    init() {
        loadChallenge()
        updateCurrentDay() // 初始化时更新当前天数
    }
    
    // MARK: - 数据持久化
    private func loadChallenge() {
        if let data = userDefaults.data(forKey: challengeKey),
           let challenge = try? JSONDecoder().decode(Challenge.self, from: data) {
            self.currentChallenge = challenge
        }
    }
    
    private func saveChallenge() {
        if let challenge = currentChallenge,
           let data = try? JSONEncoder().encode(challenge) {
            userDefaults.set(data, forKey: challengeKey)
        }
    }
    
    // MARK: - 日期管理
    private func updateCurrentDay() {
    guard var challenge = currentChallenge else { return }
    let calendar = Calendar.current
    if let daysSinceStart = calendar.dateComponents([.day], from: challenge.startDate, to: Date()).day {
        let newDay = daysSinceStart + 1 // 因为第一天是第1天，而不是第0天
        if newDay != challenge.currentDay {
            // 1. 更新天数
            challenge.currentDay = min(newDay, 50) // 确保不超过50天
            
            // 2. 重置所有任务状态
            for i in 0..<challenge.tasks.count {
                challenge.tasks[i].isCompleted = false
            }
            
            // 3. 保存更改
            currentChallenge = challenge
            saveChallenge()
          }   
        }
    }
    
    // MARK: - 挑战管理
    func startNewChallenge(with tasks: [Task]) {
        currentChallenge = Challenge(tasks: tasks)
        saveChallenge()
    }
    
    func resetChallenge() {
        if let tasks = currentChallenge?.tasks {
            startNewChallenge(with: tasks.map { Task(title: $0.title, description: $0.description, category: $0.category) })
        }
    }
    
    // MARK: - 任务管理
    func toggleTask(_ task: Task) {
        guard var challenge = currentChallenge else { return }
        if let index = challenge.tasks.firstIndex(where: { $0.id == task.id }) {
            challenge.tasks[index].isCompleted.toggle()
            
            // 检查是否所有任务都完成
            if challenge.tasks.allSatisfy({ $0.isCompleted }) {
                challenge.completedDays.insert(challenge.currentDay)
            } else {
                challenge.completedDays.remove(challenge.currentDay)
            }
            
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    func updateTaskDescription(_ task: Task, newDescription: String) {
        guard var challenge = currentChallenge else { return }
        if let index = challenge.tasks.firstIndex(where: { $0.id == task.id }) {
            challenge.tasks[index].description = newDescription
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    // MARK: - 日记管理
    func addJournalEntry(content: String) {
        guard var challenge = currentChallenge else { return }
        let journal = Journal(date: Date(), content: content, dayNumber: challenge.currentDay)
        
        // 如果已经存在当天的日记，就更新它
        if let index = challenge.journals.firstIndex(where: { $0.dayNumber == challenge.currentDay }) {
            challenge.journals[index] = journal
        } else {
            challenge.journals.append(journal)
        }
        
        currentChallenge = challenge
        saveChallenge()
    }
    
    func updateJournalEntry(_ journal: Journal, newContent: String) {
        guard var challenge = currentChallenge else { return }
        if let index = challenge.journals.firstIndex(where: { $0.id == journal.id }) {
            var updatedJournal = journal
            updatedJournal.content = newContent
            challenge.journals[index] = updatedJournal
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    // MARK: - 状态检查
    func checkChallengeStatus() {
        updateCurrentDay() // 每次检查状态时更新当前天数
    }
    
    // MARK: - 辅助方法
    func getJournal(for day: Int) -> Journal? {
        return currentChallenge?.journals.first { $0.dayNumber == day }
    }
    
    func getDayStatus(day: Int) -> DayStatus {
        guard let challenge = currentChallenge else { return .init(taskState: .upcoming, hasJournal: false) }
        
        // 1. 判断日记状态（只需要检查这一天是否有日记）
        let hasJournal = getJournal(for: day) != nil
        
        // 2. 判断任务状态
        let taskState: TaskState
        
        if day > challenge.currentDay {
            // 未来日期
            taskState = .upcoming
        } else if day == challenge.currentDay {
            // 当天 - 根据任务完成情况返回不同状态
            if challenge.isTasksCompleted(forDay: day) {
                taskState = .completed
            } else {
                taskState = .current
            }
        } else {
            // 过去的日期
            if challenge.isTasksCompleted(forDay: day) {
                taskState = .completed
            } else {
                taskState = .failed
            }
        }
        
        return DayStatus(taskState: taskState, hasJournal: hasJournal)
    }
}

// MARK: - 辅助类型
enum TaskState {
    case upcoming   // 未来日期
    case current    // 当前日期（未完成）
    case completed  // 任务已完成
    case failed     // 过去日期（未完成）
}

struct DayStatus {
    let taskState: TaskState
    let hasJournal: Bool
    
    var color: Color {
        switch taskState {
        case .upcoming:
            return .gray
        case .current:
            return .yellow
        case .completed:
            return .yellow.opacity(0.8)
        case .failed:
            return .red
        }
    }
    
    var borderColor: Color {
        if hasJournal {
            return .yellow.opacity(0.9)
        }
        return color
    }
    
    var showCheckmark: Bool {
        taskState == .completed
    }
    
    var borderWidth: CGFloat {
        hasJournal ? 2 : 1
    }
} 