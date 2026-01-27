//
//  CreateRideView.swift
//  PoolPals
//

import SwiftUI
import Dispatch

struct CreateRideView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var route: String = ""
    @State private var time: Date = Date()
    @State private var seatsAvailable: Int = 1

    @State private var carNumber: String = ""
    @State private var carModel: String = ""

    @State private var errorMessage: String?

    let ownerName: String
    let onRideCreated: () -> Void

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Route
                Section(header: Text("Route")) {
                    TextField("Enter route", text: $route)
                }

                // MARK: - Time
                Section(header: Text("Time")) {
                    DatePicker(
                        "Departure Time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                }

                // MARK: - Seats
                Section(header: Text("Seats")) {
                    Stepper(value: $seatsAvailable, in: 1...6) {
                        Text("Seats Available: \(seatsAvailable)")
                    }
                }

                // MARK: - Car Details
                Section(header: Text("Car Details")) {
                    TextField("Car Model", text: $carModel)
                    TextField("Car Number", text: $carNumber)
                }

                // MARK: - Error
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                // MARK: - Submit
                Button("Post Ride") {
                    createRide()
                }
                .disabled(
                    route.isEmpty ||
                    carModel.isEmpty ||
                    carNumber.isEmpty
                )
            }
            .navigationTitle("Post Ride")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Create Ride

    private func createRide() {
        RideService.shared.createRide(
            route: route,
            time: time,
            seatsAvailable: seatsAvailable,
            carNumber: carNumber,
            carModel: carModel,
            ownerName: ownerName
        ) { result in
            DispatchQueue.main.async(execute: {
                switch result {
                case .success:
                    errorMessage = nil
                    onRideCreated()
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            })
        }
    }
}
