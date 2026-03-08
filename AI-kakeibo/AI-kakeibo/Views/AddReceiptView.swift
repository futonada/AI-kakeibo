import SwiftUI
import PhotosUI

struct AddReceiptView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysisResult: ReceiptResponseDTO?
    @State private var errorMessage: String?
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("レシートを選択してください")
                    .foregroundStyle(.secondary)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("フォトライブラリから選択", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAnalyzing)

                if isAnalyzing {
                    ProgressView("解析中...")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("レシート追加")
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task { await analyzeImage(from: newItem) }
            }
            .navigationDestination(isPresented: $showConfirm) {
                if let result = analysisResult {
                    ReceiptConfirmView(dto: result) {
                        analysisResult = nil
                        selectedItem = nil
                    }
                }
            }
        }
    }

    private func analyzeImage(from item: PhotosPickerItem) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw URLError(.cannotDecodeContentData)
            }
            let result = try await APIClient.shared.analyzeReceipt(imageData: data, mimeType: "image/jpeg")
            analysisResult = result
            showConfirm = true
        } catch {
            errorMessage = "解析に失敗しました: \(error.localizedDescription)"
        }
    }
}
