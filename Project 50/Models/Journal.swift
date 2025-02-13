import Foundation

struct Journal: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var content: String
    var dayNumber: Int // 第几天（1-50）
} 