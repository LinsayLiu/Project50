import Foundation

struct Challenge: Identifiable, Codable {
    var id: UUID = UUID()
    var startDate: Date
    var currentDay: Int
    var tasks: [Task]
    var journals: [Journal]
    var status: ChallengeStatus
    
    enum ChallengeStatus: String, Codable {
        case ongoing = "进行中"
        case completed = "已完成"
        case failed = "已中断"
    }
    
    // 计算属性：当前挑战是否失败
    var isFailed: Bool {
        if let lastCompletedDay = journals.last?.dayNumber {
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            return daysSinceStart > lastCompletedDay + 1
        }
        return false
    }
    
    // 计算属性：今天的任务是否全部完成
    var isTodayCompleted: Bool {
        tasks.allSatisfy { $0.isCompleted }
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
        self.journals = []
        self.status = .ongoing
    }
} 