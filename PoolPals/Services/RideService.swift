//
//  RideService.swift
//  PoolPals
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class RideService {

    static let shared = RideService()
    private let db = Firestore.firestore()

    private init() {}

    // Create Ride

    func createRide(
        route: String,
        startDateTime: Date,
        seatsAvailable: Int,
        carNumber: String,
        carModel: String,
        ownerName: String,
        startLocationName: String,
        endLocationName: String,
        startLatitude: Double,
        startLongitude: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1)))
            return
        }

        let data: [String: Any] = [
            "ownerId": userId,
            "ownerName": ownerName,
            "route": route,
            "time": Timestamp(date: startDateTime),
            "seatsAvailable": max(seatsAvailable, 0),
            "carNumber": carNumber,
            "carModel": carModel,
            "startLocationName": startLocationName,
            "endLocationName": endLocationName,
            "startLatitude": startLatitude,
            "startLongitude": startLongitude
        ]

        db.collection("rides").addDocument(data: data) { error in
            error == nil ? completion(.success(())) : completion(.failure(error!))
        }
    }

    // Fetch Rides
    func fetchRides(
        completion: @escaping (Result<[Ride], Error>) -> Void
    ) {
        db.collection("rides")
            .order(by: "time", descending: false)
            .getDocuments { snapshot, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                let rides: [Ride] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let ownerId = data["ownerId"] as? String,
                        let ownerName = data["ownerName"] as? String,
                        let route = data["route"] as? String,
                        let startLocationName = data["startLocationName"] as? String,
                        let endLocationName = data["endLocationName"] as? String,
                        let startLatitude = data["startLatitude"] as? Double,
                        let startLongitude = data["startLongitude"] as? Double,
                        let startDateTime = (data["time"] as? Timestamp)?.dateValue(),
                        let seats = data["seatsAvailable"] as? Int,
                        let carNumber = data["carNumber"] as? String,
                        let carModel = data["carModel"] as? String
                    else {
                        return nil
                    }

                    return Ride(
                        id: doc.documentID,
                        ownerId: ownerId,
                        ownerName: ownerName,
                        route: route,
                        startLocationName: startLocationName,
                        endLocationName: endLocationName,
                        startLatitude: startLatitude,
                        startLongitude: startLongitude,
                        startDateTime: startDateTime,
                        seatsAvailable: seats,
                        carNumber: carNumber,
                        carModel: carModel
                    )
                } ?? []

                completion(.success(rides))
            }
    }

    // Fetch Requests (OWNER)

    func fetchRequests(
        rideId: String,
        completion: @escaping (Result<[RideRequest], Error>) -> Void
    ) {
        db.collection("rides")
            .document(rideId)
            .collection("requests")
            .getDocuments { snapshot, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                let requests: [RideRequest] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()

                    guard
                        let userId = data["userId"] as? String,
                        let rawStatus = data["status"] as? String,
                        let status = RideRequestStatus(rawValue: rawStatus)
                    else {
                        return nil
                    }

                    return RideRequest(
                        id: doc.documentID,
                        userId: userId,
                        status: status,
                        userName: nil
                    )
                } ?? []

                completion(.success(requests))
            }
    }

    // Fetch Current User Request

    func fetchUserRequest(
        rideId: String,
        userId: String,
        completion: @escaping (RideRequest?) -> Void
    ) {
        db.collection("rides")
            .document(rideId)
            .collection("requests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, _ in

                guard
                    let doc = snapshot?.documents.first,
                    let raw = doc.data()["status"] as? String,
                    let status = RideRequestStatus(rawValue: raw)
                else {
                    completion(nil)
                    return
                }

                completion(
                    RideRequest(
                        id: doc.documentID,
                        userId: userId,
                        status: status,
                        userName: nil
                    )
                )
            }
    }


    // Approve Request

    func approveRequest(
        rideId: String,
        requestId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let rideRef = db.collection("rides").document(rideId)
        let requestRef = rideRef.collection("requests").document(requestId)

        db.runTransaction({ transaction, errorPointer in

            let rideSnap: DocumentSnapshot
            let requestSnap: DocumentSnapshot

            do {
                rideSnap = try transaction.getDocument(rideRef)
                requestSnap = try transaction.getDocument(requestRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            // Validate seats
            guard
                let seats = rideSnap.data()?["seatsAvailable"] as? Int,
                seats > 0
            else {
                errorPointer?.pointee = NSError(
                    domain: "RideError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No seats available"]
                )
                return nil
            }

            // Get approved userId
            guard let userId = requestSnap.data()?["userId"] as? String else {
                errorPointer?.pointee = NSError(
                    domain: "RideError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid request data"]
                )
                return nil
            }

            // 1. Decrement seat count
            transaction.updateData(
                ["seatsAvailable": seats - 1],
                forDocument: rideRef
            )

            // 2. Approve request
            transaction.updateData(
                ["status": RideRequestStatus.approved.rawValue],
                forDocument: requestRef
            )

            // 3. Mark ride as joined for user
            let joinedRideRef = self.db
                .collection("users")
                .document(userId)
                .collection("joinedRides")
                .document(rideId)

            transaction.setData(
                ["joinedAt": FieldValue.serverTimestamp()],
                forDocument: joinedRideRef
            )

            return nil

        }) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Withdraw Request
    func withdrawRequest(
        rideId: String,
        requestId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let rideRef = db.collection("rides").document(rideId)
        let requestRef = rideRef.collection("requests").document(requestId)

        db.runTransaction({ transaction, errorPointer in

            let rideSnap: DocumentSnapshot
            let requestSnap: DocumentSnapshot

            do {
                rideSnap = try transaction.getDocument(rideRef)
                requestSnap = try transaction.getDocument(requestRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let status = requestSnap.data()?["status"] as? String
            let seats = rideSnap.data()?["seatsAvailable"] as? Int ?? 0
            let userId = requestSnap.data()?["userId"] as? String

            if status == RideRequestStatus.approved.rawValue {
                transaction.updateData(
                    ["seatsAvailable": seats + 1],
                    forDocument: rideRef
                )

                if let userId {
                    let joinedRideRef = self.db
                        .collection("users")
                        .document(userId)
                        .collection("joinedRides")
                        .document(rideId)

                    transaction.deleteDocument(joinedRideRef)
                }
            }

            transaction.deleteDocument(requestRef)
            return nil

        }) { _, error in
            error == nil ? completion(.success(())) : completion(.failure(error!))
        }
    }



    // Delete Ride

    func deleteRide(
        rideId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let rideRef = db.collection("rides").document(rideId)
        let requestsRef = rideRef.collection("requests")

        requestsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let batch = self.db.batch()
            snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(rideRef)
            
            let usersRef = self.db.collection("users")
            usersRef.getDocuments { usersSnapshot, _ in
                usersSnapshot?.documents.forEach { userDoc in
                    let joinedRideRef = userDoc.reference
                        .collection("joinedRides")
                        .document(rideId)
                    batch.deleteDocument(joinedRideRef)
                }
            }

            batch.commit { error in
                error == nil ? completion(.success(())) : completion(.failure(error!))
            }
        }
    }
    
    // Request to Join Ride (Duplicate Safe)

    func requestToJoinRide(
        rideId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1)))
            return
        }

        let requestsRef = db
            .collection("rides")
            .document(rideId)
            .collection("requests")

        // Prevent duplicate requests by same user
        requestsRef
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    completion(
                        .failure(
                            NSError(
                                domain: "RideRequest",
                                code: 1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                    "You have already requested this ride."
                                ]
                            )
                        )
                    )
                    return
                }

                let data: [String: Any] = [
                    "userId": userId,
                    "status": RideRequestStatus.pending.rawValue
                ]

                requestsRef.addDocument(data: data) { error in
                    error == nil
                        ? completion(.success(()))
                        : completion(.failure(error!))
                }
            }
    }
    
    // Send Message (Ride Chat)

    func sendMessage(
        rideId: String,
        text: String,
        senderName: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "AuthError", code: -1))
            return
        }

        let data: [String: Any] = [
            "senderId": userId,
            "senderName": senderName,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("rides")
            .document(rideId)
            .collection("messages")
            .addDocument(data: data) { error in
                completion?(error)
            }
    }
    
    // Fetched joined Rides
    func fetchJoinedRideIds(
        userId: String,
        completion: @escaping ([String]) -> Void
    ) {
        db.collection("users")
            .document(userId)
            .collection("joinedRides")
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.map { $0.documentID } ?? []
                completion(ids)
            }
    }
    
    // Search Ride
    
    func searchRides(
        start: String,
        end: String,
        from: Date?,
        to: Date?,
        completion: @escaping ([Ride]) -> Void
    ) {
        var query = db.collection("rides").order(by: "time")

        if let from {
            query = query.whereField("time", isGreaterThanOrEqualTo: from)
        }

        if let to {
            query = query.whereField("time", isLessThanOrEqualTo: to)
        }

        query.getDocuments { snapshot, _ in
            let rides = snapshot?.documents.compactMap { doc -> Ride? in
                let data = doc.data()

                guard
                    let ownerId = data["ownerId"] as? String,
                    let ownerName = data["ownerName"] as? String,
                    let route = data["route"] as? String,
                    let startLocationName = data["startLocationName"] as? String,
                    let endLocationName = data["endLocationName"] as? String,
                    let startLatitude = data["startLatitude"] as? Double,
                    let startLongitude = data["startLongitude"] as? Double,
                    let startDateTime = (data["time"] as? Timestamp)?.dateValue(),
                    let seats = data["seatsAvailable"] as? Int,
                    let carNumber = data["carNumber"] as? String,
                    let carModel = data["carModel"] as? String
                else { return nil }

                return Ride(
                    id: doc.documentID,
                    ownerId: ownerId,
                    ownerName: ownerName,
                    route: route,
                    startLocationName: startLocationName,
                    endLocationName: endLocationName,
                    startLatitude: startLatitude,
                    startLongitude: startLongitude,
                    startDateTime: startDateTime,
                    seatsAvailable: seats,
                    carNumber: carNumber,
                    carModel: carModel
                )
            } ?? []

            completion(
                rides.filter {
                    (start.isEmpty || $0.startLocationName.localizedCaseInsensitiveContains(start)) &&
                    (end.isEmpty || $0.endLocationName.localizedCaseInsensitiveContains(end))
                }
            )
        }
    }

    
    func deleteAccount(
        userId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let userRef = db.collection("users").document(userId)

        userRef.collection("joinedRides").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let joinedRideIds = snapshot?.documents.map { $0.documentID } ?? []

            let group = DispatchGroup()

            for rideId in joinedRideIds {
                group.enter()

                self.handleSeatCleanup(
                    rideId: rideId,
                    userId: userId
                ) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                // Delete user Firestore document
                userRef.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    private func handleSeatCleanup(
        rideId: String,
        userId: String,
        completion: @escaping () -> Void
    ) {
        let rideRef = db.collection("rides").document(rideId)

        let requestQuery = rideRef
            .collection("requests")
            .whereField("userId", isEqualTo: userId)

        requestQuery.getDocuments { snapshot, _ in
            guard let requestDoc = snapshot?.documents.first else {
                completion()
                return
            }

            self.cleanupTransaction(
                rideRef: rideRef,
                requestRef: requestDoc.reference,
                userId: userId,
                rideId: rideId,
                completion: completion
            )
        }
    }
    
    
    private func cleanupTransaction(
        rideRef: DocumentReference,
        requestRef: DocumentReference,
        userId: String,
        rideId: String,
        completion: @escaping () -> Void
    ) {
        db.runTransaction({ transaction, errorPointer in

            let rideSnap: DocumentSnapshot
            let requestSnap: DocumentSnapshot

            do {
                rideSnap = try transaction.getDocument(rideRef)
                requestSnap = try transaction.getDocument(requestRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let status = requestSnap.data()?["status"] as? String

            if status == RideRequestStatus.approved.rawValue {
                let seats = rideSnap.data()?["seatsAvailable"] as? Int ?? 0
                transaction.updateData(
                    ["seatsAvailable": seats + 1],
                    forDocument: rideRef
                )
            }

            // Delete request
            transaction.deleteDocument(requestRef)

            // Delete joinedRide reference
            let joinedRideRef = self.db
                .collection("users")
                .document(userId)
                .collection("joinedRides")
                .document(rideId)

            transaction.deleteDocument(joinedRideRef)

            return nil

        }) { _, _ in
            completion()
        }
    }


    
    
    
    func reportRide(
        ride: Ride,
        reason: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let reporterId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1)))
            return
        }

        let data: [String: Any] = [
            "rideId": ride.id,
            "reportedBy": reporterId,
            "rideOwnerId": ride.ownerId,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("reports").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }





}
