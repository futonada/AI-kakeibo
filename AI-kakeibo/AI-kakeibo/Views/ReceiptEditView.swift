import SwiftUI

struct ReceiptEditView: View {
    @Bindable var receipt: Receipt
    @Environment(\.dismiss) private var dismiss
    @State private var editableItems: [EditableReceiptItem]

    init(receipt: Receipt) {
        self.receipt = receipt
        _editableItems = State(initialValue: receipt.items.map {
            EditableReceiptItem(from: ReceiptItemDTO(
                name: $0.name, price: $0.price,
                quantity: $0.quantity, category: $0.category
            ))
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("店舗情報") {
                    TextField("店名", text: $receipt.storeName)
                    DatePicker("日付", selection: $receipt.date, displayedComponents: .date)
                    TextField("合計金額", value: $receipt.totalAmount, format: .number)
                        .keyboardType(.numberPad)
                }

                Section("品目") {
                    ForEach($editableItems) { $item in
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
                    .onDelete { editableItems.remove(atOffsets: $0) }
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
    }

    private func save() {
        receipt.items = editableItems.compactMap { item -> ReceiptItem? in
            guard let price = Int(item.price), let quantity = Int(item.quantity) else { return nil }
            return ReceiptItem(name: item.name, price: price, quantity: quantity, category: item.category)
        }
        dismiss()
    }
}
