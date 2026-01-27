import Foundation
import CoreLocation

struct Ride: Identifiable {

    let id: String
    let ownerId: String
    let ownerName: String

    // MARK: - Locations
    let route: String  
    let startLocationName: String
    let endLocationName: String
    let startLatitude: Double
    let startLongitude: Double

    // MARK: - Ride Details
    let time: Date
    let seatsAvailable: Int
    let carNumber: String
    let carModel: String
}
