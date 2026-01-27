//
//  RideChatViewModel.swift
//  PoolPals
//

import Foundation
import Combine
import FirebaseFirestore
import Dispatch

final class RideChatViewModel: ObservableObject {

    // MARK: - Published State

    @Published var messages: [RideMessage] = []

    // MARK: - Private

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Start Listening
    func startListening(rideId: String) {
        stopListening()

        listener = db.collection("rides")
            .document(rideId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in

                guard let self = self,
                      let documents = snapshot?.documents else { return }

                let messages = documents.compactMap { doc -> RideMessage? in
                    let data = doc.data()

                    guard
                        let senderId = data["senderId"] as? String,
                        let senderName = data["senderName"] as? String,
                        let text = data["text"] as? String
                    else {
                        return nil
                    }

                    let timestamp =
                        (data["timestamp"] as? Timestamp)?.dateValue()
                        ?? Date() // fallback while pending

                    return RideMessage(
                        id: doc.documentID,
                        senderId: senderId,
                        senderName: senderName,
                        text: text,
                        timestamp: timestamp
                    )
                }

                DispatchQueue.main.async {
                    self.messages = messages
                }
            }
    }



    // MARK: - Stop Listening

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Cleanup

    deinit {
        stopListening()
    }
}
