import Foundation

enum TranslationError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodeFailure

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not create translation URL."
        case .invalidResponse:
            return "Unexpected response from translation server."
        case .decodeFailure:
            return "Could not decode translation response."
        }
    }
}

final class MyMemoryService {
    private struct APIResponse: Decodable {
        let responseData: ResponseData
    }

    private struct ResponseData: Decodable {
        let translatedText: String
    }

    func translate(text: String, source: String, target: String) async throws -> String {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=\(source)|\(target)"

        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslationError.invalidResponse
        }

        guard let decoded = try? JSONDecoder().decode(APIResponse.self, from: data) else {
            throw TranslationError.decodeFailure
        }

        return decoded.responseData.translatedText
    }
}
