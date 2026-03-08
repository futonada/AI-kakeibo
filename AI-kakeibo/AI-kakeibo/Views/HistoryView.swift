import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                ForEach(receipts) { receipt in
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                        ReceiptRowView(receipt: receipt)
                    }
                }
                .onDelete(perform: deleteReceipts)
            }
            .navigationTitle("履歴")
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(receipts[index])
        }
    }
}
