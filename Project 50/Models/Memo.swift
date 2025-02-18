import Foundation

struct Memo: Identifiable, Codable {
    var id: UUID = UUID()
    var content: String
    var cardNumber: Int // 对应的卡片编号（1-50）
}