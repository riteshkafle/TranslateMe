import Foundation
import Combine

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = "en"
    @Published var targetLanguage = "es"
    @Published var history: [TranslationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let languageOptions: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("hi", "Hindi"),
        ("ne", "Nepali")
    ]

    private let translator = MyMemoryService()
    private let firestore = FirestoreService()

    func loadHistory() async {
        do {
            history = try await firestore.fetchTranslations()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func translate() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await translator.translate(text: trimmed, source: sourceLanguage, target: targetLanguage)
            translatedText = result

            let item = TranslationItem(
                id: UUID().uuidString,
                inputText: trimmed,
                outputText: result,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                createdAt: Date()
            )

            // Show result in history immediately, even if cloud sync fails.
            history.insert(item, at: 0)

            do {
                try await firestore.addTranslation(item)
            } catch {
                // Keep local history visible and show non-blocking sync message.
                errorMessage = "Saved locally. Firestore sync failed: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearHistory() async {
        do {
            try await firestore.clearAllTranslations()
            history.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
