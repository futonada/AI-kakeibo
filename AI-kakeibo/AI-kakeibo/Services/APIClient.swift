import Foundation

struct ReceiptItemDTO: Codable {
    var name: String
    var price: Int
    var quantity: Int
    var category: String
}

struct ReceiptResponseDTO: Codable {
    var storeName: String
    var date: String
    var totalAmount: Int
    var items: [ReceiptItemDTO]

    enum CodingKeys: String, CodingKey {
        case storeName = "store_name"
        case date
        case totalAmount = "total_amount"
        case items
    }
}

struct ReceiptItemSummary: Codable {
    let name: String
    let price: Int
    let quantity: Int
    let category: String
}

struct ReceiptSummaryDTO: Codable {
    let storeName: String
    let date: String
    let totalAmount: Int
    let items: [ReceiptItemSummary]

    enum CodingKeys: String, CodingKey {
        case storeName = "store_name"
        case date
        case totalAmount = "total_amount"
        case items
    }
}

struct ChatRequest: Codable {
    let message: String
    let receipts: [ReceiptSummaryDTO]
}

struct ChatResponse: Codable {
    let reply: String
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://ai-kakeibo-93l7.onrender.com"

    func analyzeReceipt(imageData: Data, mimeType: String) async throws -> ReceiptResponseDTO {
        let url = URL(string: "\(baseURL)/analyze-receipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ReceiptResponseDTO.self, from: data)
    }

    func chat(message: String, receipts: [ReceiptSummaryDTO]) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(message: message, receipts: receipts)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
}
