import SwiftUI
import SwiftData
import Charts

struct CategorySpending: Identifiable {
    let id = UUID()
    let category: String
    let amount: Int
}
struct StoreVisit: Identifiable {
    let id = UUID()
    let storeName: String
    let count: Int
}


struct HomeView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonthNum: Int = Calendar.current.component(.month, from: Date())

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

    private var monthlyReceipts: [Receipt] {
        allReceipts.filter {
            Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthlyTotal: Int {
        monthlyReceipts.reduce(0) { $0 + $1.totalAmount }
    }

    private var categorySpending: [CategorySpending] {
        var totals: [String: Int] = [:]
        for receipt in monthlyReceipts {
            for item in receipt.items {
                totals[item.category, default: 0] += item.price * item.quantity
            }
        }
        return totals.map { CategorySpending(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    private var storeVisitRanking: [StoreVisit] {
        var counts: [String: Int] = [:]
        for receipt in monthlyReceipts {
            counts[receipt.storeName, default: 0] += 1
        }
        return counts.map { StoreVisit(storeName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // 月選択
                    HStack(spacing: 12) {
                        Picker("年", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text("\(year)年").tag(year)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("月", selection: $selectedMonthNum) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)月").tag(month)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // 月次合計カード
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selectedYear)年\(selectedMonthNum)月の支出")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("¥\(monthlyTotal.formatted())")
                            .font(.largeTitle)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    if categorySpending.isEmpty {
                        Text("この月のデータがありません")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        // カテゴリ別棒グラフ
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ別支出")
                                .font(.headline)

                            Chart(categorySpending) { item in
                                BarMark(
                                    x: .value("金額", item.amount),
                                    y: .value("カテゴリ", item.category)
                                )
                                .foregroundStyle(by: .value("カテゴリ", item.category))
                                .annotation(position: .trailing) {
                                    Text("¥\(item.amount.formatted())")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartLegend(.hidden)
                            .chartXAxis(.hidden)
                            .frame(height: CGFloat(categorySpending.count) * 48 + 16)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        // カテゴリ別円グラフ
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ別割合")
                                .font(.headline)

                            Chart(categorySpending) { item in
                                SectorMark(
                                    angle: .value("金額", item.amount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("カテゴリ", item.category))
                                .cornerRadius(4)
                            }
                            .frame(height: 220)
                            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // お店別来店回数
                    if !storeVisitRanking.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("お店別来店回数")
                                .font(.headline)

                            Chart(storeVisitRanking) { item in
                                BarMark(
                                    x: .value("回数", item.count),
                                    y: .value("店名", item.storeName)
                                )
                                .foregroundStyle(.teal)
                                .annotation(position: .trailing) {
                                    Text("\(item.count)回")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartXAxis(.hidden)
                            .frame(height: CGFloat(storeVisitRanking.count) * 48 + 16)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }


                    // 指定月のレシート一覧
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(selectedMonthNum)月のレシート")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        if monthlyReceipts.isEmpty {
                            Text("レシートがありません")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(monthlyReceipts) { receipt in
                                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                    ReceiptRowView(receipt: receipt)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("家計簿")
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.storeName)
                .font(.headline)
            HStack {
                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("¥\(receipt.totalAmount.formatted())")
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}
