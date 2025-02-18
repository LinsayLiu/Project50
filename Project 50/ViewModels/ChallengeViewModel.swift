import Foundation
import SwiftUI

class ChallengeViewModel: ObservableObject {
    @Published var currentChallenge: Challenge?
    @Published var showingNewChallengeSheet = false
    @Published var showingMemoSheet = false
    @Published var selectedDay: SelectedDay?
    @Published var shouldShowEditTip = false
    
    private let userDefaults = UserDefaults.standard
    private let challengeKey = "current_challenge"
    private var timer: Timer?
    
    init() {
        loadChallenge()
        updateCurrentDay()
        setupTimer()
    }
    
    deinit {
        timer?.invalidate()
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
        shouldShowEditTip = true // 新建挑战时设置显示提示
        saveChallenge()
    }
    
    func resetChallenge() {
        // 清除当前挑战数据
        currentChallenge = nil
        // 清除本地存储
        userDefaults.removeObject(forKey: challengeKey)
    }
    
    func hideEditTip() {
        shouldShowEditTip = false
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
    
    // MARK: - Memo管理
    func addOrUpdateMemo(content: String, forCard cardNumber: Int) {
        guard var challenge = currentChallenge else { return }
        let memo = Memo(content: content, cardNumber: cardNumber)
        
        // 如果已经存在该卡片的memo，就更新它
        if let index = challenge.memos.firstIndex(where: { $0.cardNumber == cardNumber }) {
            challenge.memos[index] = memo
        } else {
            challenge.memos.append(memo)
        }
        
        currentChallenge = challenge
        saveChallenge()
    }
    
    func getMemo(for cardNumber: Int) -> Memo? {
        return currentChallenge?.memos.first { $0.cardNumber == cardNumber }
    }
    
    // MARK: - 状态检查
    func checkChallengeStatus() {
        updateCurrentDay() // 每次检查状态时更新当前天数
    }
    
    func getDayStatus(day: Int) -> DayStatus {
        guard let challenge = currentChallenge else { return .init(taskState: .upcoming, hasMemo: false) }
        
        // 1. 判断memo状态（只需要检查这个卡片是否有memo）
        let hasMemo = getMemo(for: day) != nil
        
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
        
        return DayStatus(taskState: taskState, hasMemo: hasMemo)
    }
    
    // MARK: - 定时器和场景监听
    private func setupTimer() {
        // 每分钟检查一次日期变化
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkChallengeStatus()
        }
    }
    
    func sceneDidBecomeActive() {
        checkChallengeStatus()
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
    let hasMemo: Bool
    
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
        if hasMemo {
            return .yellow.opacity(0.9)
        }
        return color
    }
    
    var showCheckmark: Bool {
        taskState == .completed
    }
    
    var borderWidth: CGFloat {
        hasMemo ? 2 : 1
    }
}