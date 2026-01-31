import SwiftUI
import MapKit

struct CreateRideView: View {

    @Environment(\.dismiss) private var dismiss

    // Ride Inputs
    @State private var route: String = ""
    @State private var startLocationName: String = ""
    @State private var endLocationName: String = ""

    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?

    @State private var startDateTime: Date = Date()
    @State private var seatsAvailable: Int = 1

    // Car Details
    @State private var carNumber: String = ""
    @State private var carModel: String = ""

    // Picker State
    @State private var showStartPicker = false
    @State private var showEndPicker = false

    // State
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    let ownerName: String
    let onRideCreated: () -> Void

    var body: some View {
        NavigationStack {
            Form {

                Section("Route") {
                    TextField("Short route description", text: $route)
                }

                Section("Locations") {
                    Button {
                        showStartPicker = true
                    } label: {
                        Text(startLocationName.isEmpty
                             ? "Select Start Location"
                             : startLocationName)
                    }

                    Button {
                        showEndPicker = true
                    } label: {
                        Text(endLocationName.isEmpty
                             ? "Select End Location"
                             : endLocationName)
                    }
                }

                Section("Departure") {
                    DatePicker(
                        "Date & Time",
                        selection: $startDateTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Seats") {
                    Stepper(value: $seatsAvailable, in: 1...6) {
                        Text("Seats Available: \(seatsAvailable)")
                    }
                }

                Section("Car Details") {
                    TextField("Car Model", text: $carModel)
                    TextField("Car Number", text: $carNumber)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(isSubmitting ? "Posting..." : "Post Ride") {
                    createRide()
                }
                .disabled(
                    isSubmitting ||
                    route.isEmpty ||
                    startLocationName.isEmpty ||
                    endLocationName.isEmpty ||
                    startCoordinate == nil ||
                    endCoordinate == nil ||
                    carModel.isEmpty ||
                    carNumber.isEmpty
                )
            }
            .navigationTitle("Post Ride")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showStartPicker) {
                LocationPickerView(
                    selectedName: $startLocationName,
                    selectedCoordinate: $startCoordinate
                )
            }
            .sheet(isPresented: $showEndPicker) {
                LocationPickerView(
                    selectedName: $endLocationName,
                    selectedCoordinate: $endCoordinate
                )
            }
        }
    }

    private func createRide() {
        guard let startCoordinate else {
            errorMessage = "Please select a valid start location"
            return
        }

        errorMessage = nil
        isSubmitting = true

        RideService.shared.createRide(
            route: route,
            startDateTime: startDateTime,
            seatsAvailable: seatsAvailable,
            carNumber: carNumber,
            carModel: carModel,
            ownerName: ownerName,
            startLocationName: startLocationName,
            endLocationName: endLocationName,
            startLatitude: startCoordinate.latitude,
            startLongitude: startCoordinate.longitude
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    onRideCreated()
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
