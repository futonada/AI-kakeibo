import SwiftData
import Foundation

@Model
class ReceiptItem {
    var id: UUID
    var name: String
    var price: Int
    var quantity: Int
    var category: String
    var receipt: Receipt?

    init(name: String, price: Int, quantity: Int, category: String) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.quantity = quantity
        self.category = category
    }
}
