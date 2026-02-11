import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

final class RideSearchViewModel: ObservableObject {

    @Published var results: [Ride] = []
    @Published var isLoading = false
    @Published var hasMoreResults = true

    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?


    func search(
        startName: String,
        startCoordinate: CLLocationCoordinate2D?,
        endName: String,
        endCoordinate: CLLocationCoordinate2D?,
        from: Date?,
        to: Date?
    ) {
        results = []
        lastDocument = nil
        hasMoreResults = true

        loadNextPage(
            startName: startName,
            startCoordinate: startCoordinate,
            endName: endName,
            endCoordinate: endCoordinate,
            from: from,
            to: to
        )
    }

    func loadNextPage(
        startName: String,
        startCoordinate: CLLocationCoordinate2D?,
        endName: String,
        endCoordinate: CLLocationCoordinate2D?,
        from: Date?,
        to: Date?
    ) {
        
        
        guard !isLoading, hasMoreResults else { return }
        isLoading = true

        var query: Query = Firestore.firestore()
            .collection("rides")
            .whereField("isHidden", isEqualTo: false)
            .order(by: "time")
            .limit(to: pageSize)

        // Apply time filters ONLY if user selected them
        if let from {
            query = query.whereField("time", isGreaterThanOrEqualTo: from)
        }

        if let to {
            query = query.whereField("time", isLessThanOrEqualTo: to)
        }

        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        print(query);
        
        query.getDocuments { snapshot, error in
            self.isLoading = false

            if let error {
                print("Search error:", error.localizedDescription)
                return
            }

            guard let snapshot else { return }

            self.lastDocument = snapshot.documents.last
            self.hasMoreResults = snapshot.documents.count == self.pageSize

            let blocked = SafetyState.shared.blockedUserIds
            let hiddenRides = SafetyState.shared.hiddenRideIds

            let rides = snapshot.documents.compactMap { doc -> Ride? in
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

                // Blocked users filter
                if blocked.contains(ownerId) { return nil }

                // User-hidden rides filter
                if hiddenRides.contains(doc.documentID) { return nil }

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
            }

            // Apply client-side filtering
            let filtered = rides.filter { ride in

                // Start name match (if user typed manually)
                if !startName.isEmpty &&
                    !ride.startLocationName.localizedCaseInsensitiveContains(startName) {
                    return false
                }

                // End name match
                if !endName.isEmpty &&
                    !ride.endLocationName.localizedCaseInsensitiveContains(endName) {
                    return false
                }

                // Distance filtering (only if start coordinate selected)
                if let startCoordinate {
                    let rideStart = CLLocation(
                        latitude: ride.startLatitude,
                        longitude: ride.startLongitude
                    )

                    let searchStart = CLLocation(
                        latitude: startCoordinate.latitude,
                        longitude: startCoordinate.longitude
                    )

                    let distanceKm = rideStart.distance(from: searchStart) / 1000

                    let allowedRadius = self.allowedRadiusForRide(
                        ride: ride,
                        endCoordinate: endCoordinate
                    )

                    return distanceKm <= allowedRadius
                }

                return true
            }

            DispatchQueue.main.async {
                self.results.append(contentsOf: filtered)
            }
        }
    }




    // Dynamic Radius Logic (NO HARDCODED CITIES)

    private func allowedRadiusForRide(
        ride: Ride,
        endCoordinate: CLLocationCoordinate2D?
    ) -> Double {

        guard let endCoordinate else { return 15 }

        let start = CLLocation(
            latitude: ride.startLatitude,
            longitude: ride.startLongitude
        )

        let end = CLLocation(
            latitude: endCoordinate.latitude,
            longitude: endCoordinate.longitude
        )

        let rideDistanceKm = start.distance(from: end) / 1000

        switch rideDistanceKm {
        case 0..<10:   return 3
        case 10..<30:  return 7
        case 30..<80:  return 15
        case 80..<200: return 30
        default:       return 50
        }
    }
}
