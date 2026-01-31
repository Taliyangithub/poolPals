//
//  PendingRequestsView.swift
//  PoolPals
//
//  Created by Priya Taliyan on 2026-01-30.
//


import SwiftUI

struct PendingRequestsView: View {

    @StateObject private var viewModel = PendingRequestsViewModel()

    var body: some View {
        List {

            if viewModel.pending.isEmpty {
                Text("No pending requests")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.pending) { item in
                    NavigationLink {
                        RideDetailView(
                            ride: item.ride,
                            authViewModel: AuthViewModel()
                        )
                    } label: {
                        RideRowView(ride: item.ride)
                    }
                }
            }
        }
        .navigationTitle("Pending Requests")
        .onAppear {
            viewModel.load()
        }
    }
}
