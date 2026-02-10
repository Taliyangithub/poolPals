//
//  SafetyState.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-10.
//


import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

@MainActor
final class SafetyState: ObservableObject {

    static let shared = SafetyState()

    @Published private(set) var blockedUserIds: Set<String> = []
    @Published private(set) var hiddenRideIds: Set<String> = []
    @Published private(set) var hiddenMessageIdsByRide: [String: Set<String>] = [:]

    private let db = Firestore.firestore()

    private var blockedListener: ListenerRegistration?
    private var hiddenRidesListener: ListenerRegistration?
    private var hiddenMessagesListener: ListenerRegistration?

    private init() {}

    func start() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        stop()

        // Blocked users (reactive)
        blockedListener = db.collection("users")
            .document(uid)
            .collection("blockedUsers")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                let ids = snap?.documents.map { $0.documentID } ?? []
                Task { @MainActor in self.blockedUserIds = Set(ids) }
            }

        // User-hidden rides (report-hides instantly for this user)
        hiddenRidesListener = db.collection("users")
            .document(uid)
            .collection("hiddenRides")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                let ids = snap?.documents.map { $0.documentID } ?? []
                Task { @MainActor in self.hiddenRideIds = Set(ids) }
            }

        // User-hidden messages (report-hides instantly for this user)
        hiddenMessagesListener = db.collection("users")
            .document(uid)
            .collection("hiddenMessages")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }

                var dict: [String: Set<String>] = [:]
                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    let rideId = (data["rideId"] as? String) ?? ""
                    if rideId.isEmpty { continue }
                    var set = dict[rideId] ?? []
                    set.insert(doc.documentID) // messageId as doc id
                    dict[rideId] = set
                }

                Task { @MainActor in self.hiddenMessageIdsByRide = dict }
            }
    }

    func stop() {
        blockedListener?.remove()
        blockedListener = nil

        hiddenRidesListener?.remove()
        hiddenRidesListener = nil

        hiddenMessagesListener?.remove()
        hiddenMessagesListener = nil

        blockedUserIds = []
        hiddenRideIds = []
        hiddenMessageIdsByRide = [:]
    }
}
