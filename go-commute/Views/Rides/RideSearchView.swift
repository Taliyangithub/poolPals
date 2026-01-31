import SwiftUI
import MapKit

struct RideSearchView: View {

    // Auth
    @ObservedObject var authViewModel: AuthViewModel

    // ViewModel
    @StateObject private var viewModel = RideSearchViewModel()

    // Start / End Locations
    @State private var startLocationName: String = ""
    @State private var endLocationName: String = ""

    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?

    // Picker state
    @State private var showStartPicker = false
    @State private var showEndPicker = false

    // Time filters
    @State private var useFromTime = false
    @State private var useToTime = false
    @State private var fromTime = Date()
    @State private var toTime = Date()

    var body: some View {
        NavigationStack {
            Form {

                // Locations
                Section("Locations") {

                    Button {
                        showStartPicker = true
                    } label: {
                        HStack {
                            Text("Start")
                            Spacer()
                            Text(
                                startLocationName.isEmpty
                                ? "Select location"
                                : startLocationName
                            )
                            .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showEndPicker = true
                    } label: {
                        HStack {
                            Text("End")
                            Spacer()
                            Text(
                                endLocationName.isEmpty
                                ? "Select location"
                                : endLocationName
                            )
                            .foregroundColor(.secondary)
                        }
                    }
                }

                // Time Filter
                Section("Time Filter") {

                    Toggle("After time", isOn: $useFromTime)

                    if useFromTime {
                        DatePicker(
                            "From",
                            selection: $fromTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    Toggle("Before time", isOn: $useToTime)

                    if useToTime {
                        DatePicker(
                            "To",
                            selection: $toTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Search Button
                Section {
                    Button("Search Rides") {
                        viewModel.search(
                            startName: startLocationName,
                            startCoordinate: startCoordinate,
                            endName: endLocationName,
                            endCoordinate: endCoordinate,
                            from: useFromTime ? fromTime : nil,
                            to: useToTime ? toTime : nil
                        )
                    }
                    .disabled(
                        startLocationName.isEmpty &&
                        endLocationName.isEmpty &&
                        !useFromTime &&
                        !useToTime
                    )
                }

                // Results
                if viewModel.results.isEmpty {
                    Text("No matching rides")
                        .foregroundColor(.secondary)
                } else {
                    Section("Results") {
                        ForEach(viewModel.results) { ride in
                            NavigationLink {
                                RideDetailView(
                                    ride: ride,
                                    authViewModel: authViewModel
                                )
                            } label: {
                                RideRowView(ride: ride)
                            }
                        }

                        if viewModel.hasMoreResults {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear {
                                        viewModel.loadNextPage(
                                            startName: startLocationName,
                                            startCoordinate: startCoordinate,
                                            endName: endLocationName,
                                            endCoordinate: endCoordinate,
                                            from: useFromTime ? fromTime : nil,
                                            to: useToTime ? toTime : nil
                                        )
                                    }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Rides")
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
}
