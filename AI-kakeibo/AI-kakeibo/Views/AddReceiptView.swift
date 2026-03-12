import SwiftUI
import PhotosUI

struct AddReceiptView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysisResult: ReceiptResponseDTO?
    @State private var errorMessage: String?
    @State private var showConfirm = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("レシートを選択してください")
                    .foregroundStyle(.secondary)

                Button {
                    showCamera = true
                } label: {
                    Label("カメラで撮影", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAnalyzing)

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
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    showCamera = false
                    Task { await analyzeImage(from: image) }
                }
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

    private func analyzeImage(from image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let resized = resizeImage(image, maxDimension: 1920)
            guard let data = resized.jpegData(compressionQuality: 0.7) else {
                throw URLError(.cannotDecodeContentData)
            }
            let result = try await APIClient.shared.analyzeReceipt(imageData: data, mimeType: "image/jpeg")
            analysisResult = result
            showConfirm = true
        } catch {
            errorMessage = "解析に失敗しました: \(error.localizedDescription)"
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1 else { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

}

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
