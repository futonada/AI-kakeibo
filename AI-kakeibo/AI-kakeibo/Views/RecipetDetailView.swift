import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    let receipt: Receipt
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            Section("店舗情報") {
                LabeledContent("店名", value: receipt.storeName)
                LabeledContent("日付", value: receipt.date.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("合計", value: "¥\(receipt.totalAmount.formatted())")
            }

            Section("品目") {
                ForEach(receipt.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                        HStack {
                            Text(item.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("¥\(item.price.formatted()) × \(item.quantity)")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button("このレシートを削除", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
        .navigationTitle("レシート詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ReceiptEditView(receipt: receipt)
        }
        .alert("レシートを削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                modelContext.delete(receipt)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
