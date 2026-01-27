//
//  RideListView.swift
//  PoolPals
//

import SwiftUI

struct RideListView: View {

    @StateObject private var viewModel = RideViewModel()
    @ObservedObject var authViewModel: AuthViewModel

    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            List {

                // MARK: - My Rides
                if !viewModel.myRides.isEmpty {
                    Section("My Rides") {
                        ForEach(viewModel.myRides) { ride in
                            NavigationLink {
                                RideDetailView(
                                    ride: ride,
                                    authViewModel: authViewModel
                                )

                            } label: {
                                RideRowView(ride: ride)
                            }
                        }
                    }
                }

                // MARK: - Other Rides
                if !viewModel.otherRides.isEmpty {
                    Section("Other Rides") {
                        ForEach(viewModel.otherRides) { ride in
                            NavigationLink {
                                RideDetailView(
                                    ride: ride,
                                    authViewModel: authViewModel
                                )
                            } label: {
                                RideRowView(ride: ride)
                            }
                        }
                    }
                }

                // MARK: - Empty State
                if viewModel.myRides.isEmpty && viewModel.otherRides.isEmpty {
                    ContentUnavailableView(
                        "No rides available",
                        systemImage: "car",
                        description: Text("Post a ride or check back later.")
                    )
                }
            }
            .navigationTitle("Available Rides")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        onSignOut()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Post Ride") {
                        CreateRideView(
                            ownerName: authViewModel.currentUserName ?? "Unknown"
                        ) {
                            viewModel.loadRides()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadRides()
            }
        }
    }
}
