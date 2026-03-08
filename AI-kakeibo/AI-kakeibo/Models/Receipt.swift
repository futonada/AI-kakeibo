import SwiftData
import Foundation

@Model
class Receipt {
    var id: UUID
    var storeName: String
    var date: Date
    var totalAmount: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [ReceiptItem]

    init(storeName: String, date: Date, totalAmount: Int, items: [ReceiptItem] = []) {
        self.id = UUID()
        self.storeName = storeName
        self.date = date
        self.totalAmount = totalAmount
        self.createdAt = Date()
        self.items = items
    }
}
