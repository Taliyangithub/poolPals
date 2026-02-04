//
//  BlockService.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-04.
//


import FirebaseFirestore
import FirebaseAuth

final class BlockService {

    static let shared = BlockService()
    private let db = Firestore.firestore()

    private init() {}

    func blockUser(
        blockedUserId: String,
        reason: String
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let blockRef = db
            .collection("users")
            .document(uid)
            .collection("blockedUsers")
            .document(blockedUserId)

        blockRef.setData([
            "blockedAt": FieldValue.serverTimestamp()
        ])

        db.collection("blockedReports").addDocument(data: [
            "reporterId": uid,
            "blockedUserId": blockedUserId,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func fetchBlockedUsers(
        completion: @escaping (Set<String>) -> Void
    ) {
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
