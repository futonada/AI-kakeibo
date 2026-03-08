import SwiftUI
import SwiftData

@main
struct AI_kakeiboApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Receipt.self, ReceiptItem.self])
    }
}
