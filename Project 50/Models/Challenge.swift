import Foundation

struct Challenge: Identifiable, Codable {
    var id: UUID = UUID()
    var startDate: Date
    var currentDay: Int
    var tasks: [Task]
    var memos: [Memo]  // 将journals改为memos
    var status: ChallengeStatus
    var completedDays: Set<Int> // 记录哪些天完成了所有任务
    
    enum ChallengeStatus: String, Codable {
        case ongoing = "进行中"
        case completed = "已完成"
        case failed = "已中断"
    }
    
    // 计算属性：当前挑战是否失败
    var isFailed: Bool {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart > currentDay + 1
    }
    
    // 计算属性：获取连续完成天数
    var consecutiveDays: Int {
        currentDay
    }
    
    // 初始化新的挑战
    init(tasks: [Task]) {
        self.id = UUID()
        self.startDate = Date()
        self.currentDay = 1
        self.tasks = tasks
        self.memos = []
        self.status = .ongoing
        self.completedDays = []
    }
    
    // 检查指定日期是否完成了所有任务
    func isTasksCompleted(forDay day: Int) -> Bool {
        completedDays.contains(day)
    }
}