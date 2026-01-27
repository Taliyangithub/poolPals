//
//  RideRowView.swift
//  PoolPals
//

import SwiftUI

struct RideRowView: View {

    let ride: Ride

    // MARK: - Derived Display Text

    private var routeText: String {
        if !ride.startLocationName.isEmpty &&
           !ride.endLocationName.isEmpty {
            return "\(ride.startLocationName) → \(ride.endLocationName)"
        } else {
            return ride.route
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text(routeText)
                .font(.headline)

            Text("Seats: \(ride.seatsAvailable)")
                .font(.subheadline)

            Text(ride.time, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
