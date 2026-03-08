import SwiftUI
import SwiftData

struct ReceiptConfirmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var storeName: String
    @State private var dateString: String
    @State private var totalAmount: String
    @State private var items: [EditableReceiptItem]

    let onSaved: () -> Void

    init(dto: ReceiptResponseDTO, onSaved: @escaping () -> Void) {
        _storeName = State(initialValue: dto.storeName)
        _dateString = State(initialValue: dto.date)
        _totalAmount = State(initialValue: String(dto.totalAmount))
        _items = State(initialValue: dto.items.map { EditableReceiptItem(from: $0) })
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section("店舗情報") {
                TextField("店名", text: $storeName)
                TextField("日付 (YYYY-MM-DD)", text: $dateString)
                TextField("合計金額", text: $totalAmount)
                    .keyboardType(.numberPad)
            }

            Section("品目") {
                ForEach($items) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("品名", text: $item.name)
                        HStack {
                            TextField("単価", text: $item.price)
                                .keyboardType(.numberPad)
                            Text("×")
                            TextField("数量", text: $item.quantity)
                                .keyboardType(.numberPad)
                        }
                        Picker("カテゴリ", selection: $item.category) {
                            ForEach(ReceiptCategory.allCases, id: \.rawValue) { category in
                                Text(category.rawValue).tag(category.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { items.remove(atOffsets: $0) }
            }
        }
        .navigationTitle("内容確認・修正")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
            }
        }
    }

    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: dateString) ?? Date()
        let total = Int(totalAmount) ?? 0

        let receiptItems = items.compactMap { item -> ReceiptItem? in
            guard let price = Int(item.price), let quantity = Int(item.quantity) else { return nil }
            return ReceiptItem(name: item.name, price: price, quantity: quantity, category: item.category)
        }

        let receipt = Receipt(storeName: storeName, date: date, totalAmount: total, items: receiptItems)
        modelContext.insert(receipt)
        onSaved()
        dismiss()
    }
}

struct EditableReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var price: String
    var quantity: String
    var category: String

    init(from dto: ReceiptItemDTO) {
        name = dto.name
        price = String(dto.price)
        quantity = String(dto.quantity)
        category = dto.category
    }
}

enum ReceiptCategory: String, CaseIterable {
    case food = "食費"
    case dining = "外食"
    case daily = "日用品"
    case transport = "交通"
    case medical = "医療"
    case entertainment = "娯楽"
    case other = "その他"
}
