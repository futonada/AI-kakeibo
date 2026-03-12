import SwiftUI
import SwiftData

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ChatView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonthNum: Int = Calendar.current.component(.month, from: Date())
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    private var selectedMonth: Date {
    var components = DateComponents()
    components.year = selectedYear
    components.month = selectedMonthNum
    components.day = 1
    return Calendar.current.date(from: components) ?? Date()
}

    private var availableYears: [Int] {
    let current = Calendar.current.component(.year, from: Date())
    return Array((current - 3)...current)
}


    private var filteredReceipts: [Receipt] {
        let calendar = Calendar.current
        return allReceipts.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        
                        HStack(spacing: 16) {
                            Text("対象月:")
                                .foregroundStyle(.secondary)
                            Picker("年", selection: $selectedYear) {
                                ForEach(availableYears, id: \.self) { year in
                                    Text("\(year)年").tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedYear) { _, _ in messages = [] }

                            Picker("月", selection: $selectedMonthNum) {
                                ForEach(1...12, id: \.self) { month in
                                    Text("\(month)月").tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedMonthNum) { _, _ in messages = [] }

                            Spacer()
                        }
                        .padding(.horizontal)
                        


                        Divider()

                        if messages.isEmpty {
                            Text("選択した月の家計について\n自由に相談してください")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        }
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField("メッセージを入力", text: $inputText, axis: .vertical)
                            .lineLimit(1...4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Button {
                            Task { await sendMessage() }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                }
            }
            .navigationTitle("AI相談")
        }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        inputText = ""
        messages.append(ChatMessage(content: text, isUser: true))
        isLoading = true


        let receiptDTOs = filteredReceipts.map { receipt in
            ReceiptSummaryDTO(
                storeName: receipt.storeName,
                date: receipt.date.formatted(.iso8601.year().month().day()),
                totalAmount: receipt.totalAmount,
                items: receipt.items.map {
                    ReceiptItemSummary(name: $0.name, price: $0.price, quantity: $0.quantity, category: $0.category)
                }
            )
        }

        do {
            let response = try await APIClient.shared.chat(message: text, receipts: receiptDTOs)
            messages.append(ChatMessage(content: response.reply, isUser: false))
        } catch {
            messages.append(ChatMessage(content: "エラーが発生しました: \(error.localizedDescription)", isUser: false))
        }

        isLoading = false
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}
