//
//  LocationPickerView.swift
//  PoolPals
//
//  Created by Priya Taliyan on 2026-01-30.
//


import SwiftUI
import MapKit

struct LocationPickerView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var selectedName: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var searchText = ""
    @State private var results: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            List(results, id: \.self) { item in
                Button {
                    selectedName = item.name ?? ""
                    selectedCoordinate = item.placemark.coordinate
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "")
                        Text(item.placemark.title ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Location")
            .onChange(of: searchText) { _, newValue in
                search(query: newValue)
            }
        }
    }

    private func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        Task {
            let response = try? await MKLocalSearch(request: request).start()
            await MainActor.run {
                results = response?.mapItems ?? []
            }
        }
    }
}
