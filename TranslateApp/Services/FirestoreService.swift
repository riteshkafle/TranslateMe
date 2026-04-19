import Foundation
import FirebaseFirestore

final class FirestoreService {
    private let db = Firestore.firestore()
    private let collection = "translations"

    func addTranslation(_ item: TranslationItem) async throws {
        let payload: [String: Any] = [
            "id": item.id,
            "inputText": item.inputText,
            "outputText": item.outputText,
            "sourceLanguage": item.sourceLanguage,
            "targetLanguage": item.targetLanguage,
            "createdAt": Timestamp(date: item.createdAt)
        ]

        try await db.collection(collection).document(item.id).setData(payload)
    }

    func fetchTranslations() async throws -> [TranslationItem] {
        let snapshot = try await db.collection(collection)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard
                let id = (data["id"] as? String) ?? Optional(doc.documentID),
                let inputText = data["inputText"] as? String,
                let outputText = data["outputText"] as? String,
                let sourceLanguage = data["sourceLanguage"] as? String,
                let targetLanguage = data["targetLanguage"] as? String,
                let timestamp = data["createdAt"] as? Timestamp
            else {
                return nil
            }

            return TranslationItem(
                id: id,
                inputText: inputText,
                outputText: outputText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                createdAt: timestamp.dateValue()
            )
        }
    }

    func clearAllTranslations() async throws {
        let snapshot = try await db.collection(collection).getDocuments()

        for doc in snapshot.documents {
            try await db.collection(collection).document(doc.documentID).delete()
        }
    }
}
