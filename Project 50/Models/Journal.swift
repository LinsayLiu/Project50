import Foundation

struct Journal: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var content: String
    var mood: Mood
    var dayNumber: Int // 第几天（1-50）
    
    enum Mood: String, Codable, CaseIterable {
        case excellent = "非常好"
        case good = "很好"
        case normal = "一般"
        case bad = "不太好"
        case terrible = "很差"
        
        var icon: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "sun.max.fill"
            case .normal: return "cloud.sun.fill"
            case .bad: return "cloud.fill"
            case .terrible: return "cloud.rain.fill"
            }
        }
    }
} 