//
//  PendingRideRequest.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-01-30.
//


import Foundation

struct PendingRideRequest: Identifiable {
    let id: String          // requestId
    let rideId: String
    let ride: Ride
}
