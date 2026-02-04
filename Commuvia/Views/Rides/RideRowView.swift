//
//  RideRowView.swift
//  Commuvia
//

import SwiftUI

struct RideRowView: View {

    let ride: Ride

    // Derived Display Text

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
            
            Text(ride.startDateTime, format: .dateTime.day().month().hour().minute())
                .font(.caption)
                .foregroundColor(.gray)


        }
        .padding(.vertical, 4)
    }
}
