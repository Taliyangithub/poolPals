import Foundation

struct RideRequest: Identifiable {
    let id: String
    let userId: String
    let status: RideRequestStatus
    let userName: String?
}

