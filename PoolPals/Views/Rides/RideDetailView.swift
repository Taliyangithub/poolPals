//
//  RideDetailView.swift
//  PoolPals
//

import SwiftUI
import Dispatch

struct RideDetailView: View {

    @StateObject private var viewModel: RideDetailViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) private var dismiss
    
    var currentUserName: String {
        authViewModel.currentUserName ?? "Unknown"
    }

    init(ride: Ride, authViewModel: AuthViewModel) {
        _viewModel = StateObject(
            wrappedValue: RideDetailViewModel(ride: ride)
        )
        self.authViewModel = authViewModel
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // MARK: - Ride Header

                Text(viewModel.ride.route)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Posted by: \(viewModel.ride.ownerName)")
                        .font(.subheadline)

                    Text("Car: \(viewModel.ride.carModel)")
                        .font(.subheadline)

                    Text("Car Number: \(viewModel.ride.carNumber)")
                        .font(.subheadline)
                }

                Divider()

                // MARK: - Ride Info

                Text("Seats available: \(viewModel.ride.seatsAvailable)")
                Text(viewModel.ride.time, style: .time)
                
                // Mark: - Chat
                
                NavigationLink("Open Chat") {
                    RideChatView(
                        ride: viewModel.ride,
                        currentUserName: authViewModel.currentUserName ?? "Unknown"
                    )
                }
                .buttonStyle(.bordered)


                // MARK: - Actions

                if viewModel.isOwner {
                    ownerSection
                } else {
                    nonOwnerSection
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Ride Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadRequests()
            }
            .onChange(of: viewModel.rideDeleted) { _, deleted in
                if deleted {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Non Owner (Requester)

    private var nonOwnerSection: some View {
        Group {
            if viewModel.ride.seatsAvailable <= 0 {
                Text("No seats available")
                    .foregroundColor(.gray)
            }
            else if let status = viewModel.userRequestStatus {

                VStack(spacing: 8) {
                    Text("Request status: \(status.rawValue.capitalized)")
                        .foregroundColor(.gray)

                    if status == .pending {
                        Button("Withdraw Request") {
                            viewModel.withdrawRequest()
                        }
                    }
                }

            } else {
                Button("Request to Join") {
                    viewModel.requestToJoin()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Owner Section

    private var ownerSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Button(role: .destructive) {
                viewModel.deleteRide()
            } label: {
                Text("Delete Ride")
            }

            Text("Requests")
                .font(.headline)

            List(viewModel.requests) { request in
                HStack {
                    Text(request.userName ?? request.userId)
                        .font(.caption)

                    Spacer()

                    if request.status == .pending {
                        Button("Approve") {
                            viewModel.approve(requestId: request.id)
                        }
                    } else if request.status == .approved {
                        Button("Remove") {
                            viewModel.withdrawRequest()
                        }
                    } else {
                        Text(request.status.rawValue.capitalized)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(minHeight: 150)
        }
    }
}
