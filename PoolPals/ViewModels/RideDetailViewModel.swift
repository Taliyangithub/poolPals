//
//  RideDetailViewModel.swift
//  PoolPals
//

import Foundation
import Combine
import FirebaseAuth
import Dispatch

final class RideDetailViewModel: ObservableObject {

    // Published State

    @Published var requests: [RideRequest] = []
    @Published var errorMessage: String?
    @Published var userRequestStatus: RideRequestStatus?
    @Published var userRequestId: String?
    @Published var rideDeleted: Bool = false

    // Properties

    let ride: Ride

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // Init

    init(ride: Ride) {
        self.ride = ride
        loadUserRequest()
    }

    // Computed

    var isOwner: Bool {
        ride.ownerId == currentUserId
    }

    // User Actions

    func requestToJoin() {
        RideService.shared.requestToJoinRide(rideId: ride.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadUserRequest()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func withdrawRequest() {
        guard let requestId = userRequestId else { return }

        RideService.shared.withdrawRequest(
            rideId: ride.id,
            requestId: requestId
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.userRequestStatus = nil
                    self?.userRequestId = nil
                    self?.loadRequests()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Owner Actions

    func loadRequests() {
        guard isOwner else { return }

        RideService.shared.fetchRequests(rideId: ride.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let requests):
                    self?.loadUserNames(for: requests)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func approve(requestId: String) {
        RideService.shared.approveRequest(
            rideId: ride.id,
            requestId: requestId
        ) { [weak self] result in
            DispatchQueue.main.async {
                if case .success = result {
                    self?.loadRequests()
                }
            }
        }
    }

    // Helpers

    private func loadUserRequest() {
        guard let userId = currentUserId else { return }

        RideService.shared.fetchUserRequest(
            rideId: ride.id,
            userId: userId
        ) { [weak self] request in
            DispatchQueue.main.async {
                self?.userRequestStatus = request?.status
                self?.userRequestId = request?.id
            }
        }
    }

    private func loadUserNames(for requests: [RideRequest]) {
        let group = DispatchGroup()
        var updatedRequests = requests

        for index in updatedRequests.indices {
            group.enter()

            AuthService.shared.fetchUserName(
                userId: updatedRequests[index].userId
            ) { name in
                updatedRequests[index].userName = name
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.requests = updatedRequests
        }
    }

    // Delete Ride

    func deleteRide() {
        RideService.shared.deleteRide(rideId: ride.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.rideDeleted = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
