import Foundation

struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var isCompleted: Bool = false
    var category: TaskCategory
    var reminderTime: Date?
    
    enum TaskCategory: String, Codable, CaseIterable {
        case wakeUp = "早起"
        case morningRoutine = "晨间仪式"
        case exercise = "运动"
        case reading = "阅读"
        case learning = "学习"
        case diet = "饮食"
        case journal = "日记"
        case custom = "自定义"
        
        var icon: String {
            switch self {
            case .wakeUp: return "sunrise.fill"
            case .morningRoutine: return "sun.and.horizon.fill"
            case .exercise: return "figure.run"
            case .reading: return "book.fill"
            case .learning: return "brain.head.profile"
            case .diet: return "leaf.fill"
            case .journal: return "note.text"
            case .custom: return "star.fill"
            }
        }
    }
}

// 预设任务模板
extension Task {
    static let templates: [Task] = [
        Task(title: "早起", description: "每天7点起床", category: .wakeUp),
        Task(title: "晨间仪式", description: "冥想、整理或早餐", category: .morningRoutine),
        Task(title: "运动", description: "每天1小时运动", category: .exercise),
        Task(title: "阅读", description: "每天阅读10页书籍", category: .reading),
        Task(title: "学习新技能", description: "练习写作1小时", category: .learning),
        Task(title: "健康饮食", description: "不吃垃圾食品、不喝饮料", category: .diet),
        Task(title: "写日记自省", description: "每天记录并反思当天的进展", category: .journal)
    ]
} 