import Foundation
import CoreLocation

struct Ride: Identifiable {
    let id: String
    let ownerId: String
    let ownerName: String

    // Locations
    let route: String
    let startLocationName: String
    let endLocationName: String
    let startLatitude: Double
    let startLongitude: Double

    // Ride timing
    let startDateTime: Date

    // Ride details
    let seatsAvailable: Int
    let carNumber: String
    let carModel: String
}
