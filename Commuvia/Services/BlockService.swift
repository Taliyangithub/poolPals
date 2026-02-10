//
//  BlockService.swift
//  Commuvia
//

import FirebaseFirestore
import FirebaseAuth

final class BlockService {

    static let shared = BlockService()
    private let db = Firestore.firestore()

    private init() {}


    func blockUser(
        blockedUserId: String,
        reason: String,
        context: [String: Any] = [:]
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard uid != blockedUserId else { return }

        // 1) Write block record (reactive listeners will update UI instantly)
        let blockRef = db
            .collection("users")
            .document(uid)
            .collection("blockedUsers")
            .document(blockedUserId)

        blockRef.setData([
            "blockedAt": FieldValue.serverTimestamp(),
            "reason": reason
        ], merge: true)

        // 2) Notify developer via moderation queue
        var reportData: [String: Any] = [
            "type": "block",
            "reporterId": uid,
            "blockedUserId": blockedUserId,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "status": "open"
        ]

        context.forEach { reportData[$0.key] = $0.value }

        db.collection("moderationQueue").addDocument(data: reportData)
    }


    func fetchBlockedUsers(completion: @escaping (Set<String>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .document(uid)
            .collection("blockedUsers")
            .getDocuments { snap, _ in
                let ids = snap?.documents.map { $0.documentID } ?? []
                completion(Set(ids))
            }
    }
}
