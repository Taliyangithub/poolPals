//
//  RideChatViewModel.swift
//  Commuvia
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

final class RideChatViewModel: ObservableObject {

    @Published var messages: [RideMessage] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(rideId: String) {
        stopListening()

        guard Auth.auth().currentUser != nil else { return }

        listener = db
            .collection("rides")
            .document(rideId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in

                guard let documents = snapshot?.documents else { return }

                let blocked = SafetyState.shared.blockedUserIds
                let hiddenForRide = SafetyState.shared.hiddenMessageIdsByRide[rideId] ?? []

                let msgs = documents.compactMap { doc -> RideMessage? in
                    let data = doc.data()

                    // Admin hidden (global)
                    if (data["isHidden"] as? Bool ?? false) { return nil }

                    guard
                        let senderId = data["senderId"] as? String,
                        let senderName = data["senderName"] as? String,
                        let text = data["text"] as? String
                    else { return nil }

                    // User safety filters (instant per-user)
                    if blocked.contains(senderId) { return nil }
                    if hiddenForRide.contains(doc.documentID) { return nil }

                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

                    return RideMessage(
                        id: doc.documentID,
                        senderId: senderId,
                        senderName: senderName,
                        text: text,
                        timestamp: timestamp
                    )
                }

                DispatchQueue.main.async {
                    self.messages = msgs
                }
            }
    }



    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        stopListening()
    }
}
