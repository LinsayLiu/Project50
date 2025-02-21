import Foundation
import SwiftUI

/// 挑战管理视图模型
/// 负责管理50天挑战的所有业务逻辑，包括：
/// - 任务状态管理
/// - 日期更新逻辑
/// - 数据持久化
/// - 备忘录管理
class ChallengeViewModel: ObservableObject {
    // MARK: - Published 属性
    /// 当前进行中的挑战
    @Published var currentChallenge: Challenge?
    /// 控制是否显示新挑战创建界面
    @Published var showingNewChallengeSheet = false
    /// 控制是否显示备忘录编辑界面
    @Published var showingMemoSheet = false
    /// 当前选中的天数（用于显示/编辑备忘录）
    @Published var selectedDay: SelectedDay?
    /// 控制是否显示任务编辑提示
    @Published var shouldShowEditTip = false
    
    // MARK: - 私有属性
    /// UserDefaults 实例，用于数据持久化
    private let userDefaults = UserDefaults.standard
    /// 挑战数据在 UserDefaults 中的键
    private let challengeKey = "current_challenge"
    /// 最后更新时间在 UserDefaults 中的键
    private let lastUpdateTimeKey = "last_update_time"
    /// 定时器，用于定期检查日期更新
    private var timer: Timer?
    
    // MARK: - 初始化和清理
    init() {
        loadChallenge()           // 加载已保存的挑战数据
        setupTimeZoneObserver()   // 设置时区变化监听
        setupTimeChangeObserver() // 设置系统时间变化监听
        forceUpdate()            // 强制更新一次日期
        setupTimer()             // 设置定时检查
    }
    
    deinit {
        timer?.invalidate()  // 停止定时器
        NotificationCenter.default.removeObserver(self)  // 移除所有通知观察者
    }
    
    // MARK: - 时间变化监听
    /// 设置时区变化监听器
    private func setupTimeZoneObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimeZoneChange),
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )
    }
    
    /// 设置系统时间变化监听器（如跨越午夜、系统时间调整等）
    private func setupTimeChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignificantTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
    }
    
    /// 处理时区变化
    @objc private func handleTimeZoneChange() {
        forceUpdate()
        saveLastUpdateTime()
    }
    
    /// 处理系统重大时间变化（午夜、时间校准等）
    @objc private func handleSignificantTimeChange() {
        forceUpdate()
        saveLastUpdateTime()
    }
    
    // MARK: - 数据持久化
    /// 从 UserDefaults 加载挑战数据
    private func loadChallenge() {
        if let data = userDefaults.data(forKey: challengeKey),
           let challenge = try? JSONDecoder().decode(Challenge.self, from: data) {
            self.currentChallenge = challenge
        }
    }
    
    /// 将当前挑战数据保存到 UserDefaults
    private func saveChallenge() {
        if let challenge = currentChallenge,
           let data = try? JSONEncoder().encode(challenge) {
            userDefaults.set(data, forKey: challengeKey)
        }
    }
    
    // MARK: - 日期管理
    /// 保存最后更新时间
    private func saveLastUpdateTime() {
        userDefaults.set(Date(), forKey: lastUpdateTimeKey)
    }
    
    /// 检查是否需要更新日期
    /// 通过比较最后更新日期和当前日期的0点时间来判断
    private func needsUpdate() -> Bool {
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateTimeKey) as? Date else {
            return true
        }
        
        let calendar = Calendar.autoupdatingCurrent
        // 获取最后更新时间的日期部分（去除时间）
        let lastUpdateDay = calendar.startOfDay(for: lastUpdate)
        // 获取当前时间的日期部分（去除时间）
        let today = calendar.startOfDay(for: Date())
        
        // 如果日期不同，则需要更新
        return lastUpdateDay != today
    }
    
    /// 强制更新日期
    /// 清除最后更新时间并执行更新
    private func forceUpdate() {
        userDefaults.removeObject(forKey: lastUpdateTimeKey)
        updateCurrentDay()
    }
    
    /// 更新当前天数
    /// 根据开始日期计算当前是第几天，并重置任务状态
    private func updateCurrentDay() {
        guard var challenge = currentChallenge else { return }
        
        if needsUpdate() {
            let calendar = Calendar.autoupdatingCurrent
            // 获取挑战开始日期的0点
            let startDay = calendar.startOfDay(for: challenge.startDate)
            // 获取当前日期的0点
            let today = calendar.startOfDay(for: Date())
            
            if let daysSinceStart = calendar.dateComponents([.day], from: startDay, to: today).day {
                let newDay = daysSinceStart + 1
                if newDay != challenge.currentDay {
                    challenge.currentDay = min(newDay, 50)  // 确保不超过50天
                    
                    // 重置所有任务的完成状态
                    for i in 0..<challenge.tasks.count {
                        challenge.tasks[i].isCompleted = false
                    }
                    
                    currentChallenge = challenge
                    saveChallenge()
                    saveLastUpdateTime()
                }
            }
        }
    }
    
    // MARK: - 挑战管理
    /// 开始新的挑战
    /// - Parameter tasks: 选择的任务列表
    func startNewChallenge(with tasks: [Task]) {
        currentChallenge = Challenge(tasks: tasks)
        shouldShowEditTip = true  // 显示任务编辑提示
        saveChallenge()
        saveLastUpdateTime()
    }
    
    /// 重置挑战
    /// 清除所有相关数据
    func resetChallenge() {
        currentChallenge = nil
        userDefaults.removeObject(forKey: challengeKey)
        userDefaults.removeObject(forKey: lastUpdateTimeKey)
    }
    
    /// 隐藏任务编辑提示
    func hideEditTip() {
        shouldShowEditTip = false
    }
    
    // MARK: - 任务管理
    /// 切换任务完成状态
    /// - Parameter task: 要切换状态的任务
    func toggleTask(_ task: Task) {
        guard var challenge = currentChallenge else { return }
        if let index = challenge.tasks.firstIndex(where: { $0.id == task.id }) {
            challenge.tasks[index].isCompleted.toggle()
            
            // 更新当天的完成状态
            if challenge.tasks.allSatisfy({ $0.isCompleted }) {
                challenge.completedDays.insert(challenge.currentDay)
            } else {
                challenge.completedDays.remove(challenge.currentDay)
            }
            
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    /// 更新任务描述
    /// - Parameters:
    ///   - task: 要更新的任务
    ///   - newDescription: 新的任务描述
    func updateTaskDescription(_ task: Task, newDescription: String) {
        guard var challenge = currentChallenge else { return }
        if let index = challenge.tasks.firstIndex(where: { $0.id == task.id }) {
            challenge.tasks[index].description = newDescription
            currentChallenge = challenge
            saveChallenge()
        }
    }
    
    // MARK: - Memo管理
    /// 添加或更新备忘录
    /// - Parameters:
    ///   - content: 备忘录内容
    ///   - cardNumber: 对应的天数
    func addOrUpdateMemo(content: String, forCard cardNumber: Int) {
        guard var challenge = currentChallenge else { return }
        let memo = Memo(content: content, cardNumber: cardNumber)
        
        if let index = challenge.memos.firstIndex(where: { $0.cardNumber == cardNumber }) {
            challenge.memos[index] = memo  // 更新现有备忘录
        } else {
            challenge.memos.append(memo)   // 添加新备忘录
        }
        
        currentChallenge = challenge
        saveChallenge()
    }
    
    /// 获取指定天数的备忘录
    /// - Parameter cardNumber: 天数
    /// - Returns: 对应的备忘录，如果不存在则返回nil
    func getMemo(for cardNumber: Int) -> Memo? {
        return currentChallenge?.memos.first { $0.cardNumber == cardNumber }
    }
    
    // MARK: - 状态检查
    /// 检查挑战状态
    /// 用于定时器和手动触发的状态更新
    func checkChallengeStatus() {
        updateCurrentDay()
    }
    
    /// 获取指定天数的状态
    /// - Parameter day: 要查询的天数
    /// - Returns: 包含任务状态和备忘录状态的 DayStatus
    func getDayStatus(day: Int) -> DayStatus {
        guard let challenge = currentChallenge else { return .init(taskState: .upcoming, hasMemo: false) }
        
        let hasMemo = getMemo(for: day) != nil
        let taskState: TaskState
        
        if day > challenge.currentDay {
            taskState = .upcoming  // 未来日期
        } else if day == challenge.currentDay {
            taskState = challenge.isTasksCompleted(forDay: day) ? .completed : .current  // 当天
        } else {
            taskState = challenge.isTasksCompleted(forDay: day) ? .completed : .failed  // 过去日期
        }
        
        return DayStatus(taskState: taskState, hasMemo: hasMemo)
    }
    
    // MARK: - 定时器和场景监听
    /// 设置定时检查
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkChallengeStatus()
        }
        RunLoop.current.add(timer!, forMode: .common)  // 确保在所有运行模式下都能触发
    }
    
    /// 处理场景激活事件
    /// 当应用从后台恢复时调用
    func sceneDidBecomeActive() {
        forceUpdate()
        if needsUpdate() {
            updateCurrentDay()
        }
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