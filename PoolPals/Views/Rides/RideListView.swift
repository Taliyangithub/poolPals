import SwiftUI

struct RideListView: View {

    // ViewModels
    @StateObject private var viewModel = RideViewModel()
    @ObservedObject var authViewModel: AuthViewModel

    // Safety Notice
    @AppStorage("hasSeenSafetyNotice") private var hasSeenSafetyNotice = false
    @State private var showSafetyNotice = false

    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            List {

                if viewModel.visibleRides.isEmpty {
                    ContentUnavailableView(
                        "No rides available",
                        systemImage: "car",
                        description: Text("Create a ride or join one.")
                    )
                } else {
                    ForEach(viewModel.visibleRides) { ride in
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
            .navigationTitle("My Rides")
            .toolbar {

                // Actions Menu (Apple-style)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink("Search") {
                            RideSearchView(authViewModel: authViewModel)
                        }

                        NavigationLink("Post Ride") {
                            CreateRideView(
                                ownerName: authViewModel.currentUserName ?? "Unknown"
                            ) {
                                viewModel.loadRides()
                            }
                        }

                        NavigationLink("Settings") {
                            SettingsView(
                                authViewModel: authViewModel,
                                onSignOut: onSignOut
                            )
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                viewModel.loadRides()

                // Show safety notice once per install
                if !hasSeenSafetyNotice {
                    showSafetyNotice = true
                }
            }
            .sheet(isPresented: $showSafetyNotice) {
                SafetyNoticeView {
                    hasSeenSafetyNotice = true
                    showSafetyNotice = false
                }
            }
        }
    }
}
