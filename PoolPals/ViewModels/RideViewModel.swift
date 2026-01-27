//
//  RideViewModel.swift
//  PoolPals
//

import Foundation
import Combine
import FirebaseAuth
import Dispatch

final class RideViewModel: ObservableObject {

    // MARK: - Published State

    @Published var rides: [Ride] = []
    @Published var errorMessage: String?

    // MARK: - Current User

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Derived Lists

    var myRides: [Ride] {
        guard let uid = currentUserId else { return [] }
        return rides.filter { $0.ownerId == uid }
    }

    var otherRides: [Ride] {
        guard let uid = currentUserId else { return rides }
        return rides.filter { $0.ownerId != uid }
    }

    // MARK: - Load Rides

    func loadRides() {
        RideService.shared.fetchRides { [weak self] result in
            DispatchQueue.main.async(execute: {
                switch result {
                case .success(let rides):
                    self?.rides = rides
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            })
        }
    }

    // MARK: - Refresh Helper

    func refresh() {
        loadRides()
    }
}
