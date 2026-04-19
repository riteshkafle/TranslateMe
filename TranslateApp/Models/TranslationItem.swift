import Foundation

struct TranslationItem: Identifiable, Codable {
    let id: String
    let inputText: String
    let outputText: String
    let sourceLanguage: String
    let targetLanguage: String
    let createdAt: Date
}
