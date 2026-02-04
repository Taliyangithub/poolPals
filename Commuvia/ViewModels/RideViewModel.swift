//
//  RideViewModel.swift
//  Commuvia
//

import Foundation
import Combine
import FirebaseAuth
import Dispatch
final class RideViewModel: ObservableObject {

    // Published State

    @Published var rides: [Ride] = []
    @Published var joinedRideIds: Set<String> = []
    @Published var errorMessage: String?

    // Current User

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // Visible Rides (Created OR Joined)

    var visibleRides: [Ride] {
        guard let uid = currentUserId else { return [] }

        return rides.filter {
            $0.ownerId == uid || joinedRideIds.contains($0.id)
        }
    }

    // Load All Data

    func loadRides() {
        guard let uid = currentUserId else { return }

        let group = DispatchGroup()

        group.enter()
        RideService.shared.fetchRides { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let rides) = result {
                    self?.rides = rides
                } else if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
                group.leave()
            }
        }

        group.enter()
        RideService.shared.fetchJoinedRideIds(userId: uid) { [weak self] ids in
            DispatchQueue.main.async {
                self?.joinedRideIds = Set(ids)
                group.leave()
            }
        }

        group.notify(queue: .main) { }
    }

    // Refresh Helper

    func refresh() {
        loadRides()
    }
}
