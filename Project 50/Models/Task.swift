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
        case exercise = "运动"
        case reading = "阅读"
        case learning = "学习"
        case diet = "饮食"
        case journal = "日记"
        case custom = "自定义"
        
        var icon: String {
            switch self {
            case .wakeUp: return "sunrise.fill"
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
        Task(title: "早起", description: "每天6:00起床", category: .wakeUp),
        Task(title: "运动", description: "进行1小时运动", category: .exercise),
        Task(title: "阅读", description: "阅读10页书", category: .reading),
        Task(title: "学习", description: "学习新技能", category: .learning),
        Task(title: "健康饮食", description: "记录今天的饮食", category: .diet),
        Task(title: "写日记", description: "记录今天的感想", category: .journal)
    ]
} 