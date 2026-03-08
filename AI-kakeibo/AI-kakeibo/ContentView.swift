import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            AddReceiptView()
                .tabItem {
                    Label("追加", systemImage: "camera")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }

            ChatView()
                .tabItem {
                    Label("AI相談", systemImage: "bubble.left.and.bubble.right")
                }
        }
    }
}
