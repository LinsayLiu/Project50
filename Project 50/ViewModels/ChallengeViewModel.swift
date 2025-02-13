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
            currentChallenge = challenge
            saveChallenge()
            
            // 检查是否所有任务都完成
            if challenge.isTodayCompleted {
                // 显示完成动画或提示
                // TODO: 实现完成动画
            }
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
    func addJournalEntry(content: String, mood: Journal.Mood) {
        guard var challenge = currentChallenge else { return }
        let journal = Journal(date: Date(), content: content, mood: mood, dayNumber: challenge.currentDay)
        challenge.journals.append(journal)
        
        if challenge.isTodayCompleted {
            challenge.currentDay += 1
            if challenge.currentDay > 50 {
                challenge.status = .completed
            }
        }
        
        currentChallenge = challenge
        saveChallenge()
    }
    
    // MARK: - 状态检查
    func checkChallengeStatus() {
        guard var challenge = currentChallenge else { return }
        if challenge.isFailed {
            challenge.status = .failed
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    // MARK: - 辅助方法
    func getJournal(for day: Int) -> Journal? {
        return currentChallenge?.journals.first { $0.dayNumber == day }
    }
    
    func getDayStatus(day: Int) -> DayStatus {
        guard let challenge = currentChallenge else { return .upcoming }
        
        if day > challenge.currentDay {
            return .upcoming
        }
        
        if let journal = getJournal(for: day) {
            return .completed(mood: journal.mood)
        }
        
        if day == challenge.currentDay {
            return .current
        }
        
        return .failed
    }
}

// MARK: - 辅助类型
enum DayStatus {
    case upcoming
    case current
    case completed(mood: Journal.Mood)
    case failed
    
    var color: Color {
        switch self {
        case .upcoming: return .gray
        case .current: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
} 