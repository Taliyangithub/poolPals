//
//  RideChatView.swift
//  PoolPals
//

import SwiftUI

struct RideChatView: View {

    // Inputs

    let ride: Ride
    let currentUserName: String

    // State

    @StateObject private var viewModel = RideChatViewModel()
    @State private var messageText: String = ""

    // Body

    var body: some View {
        VStack {

            List(viewModel.messages) { message in
                VStack(alignment: .leading, spacing: 4) {

                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(message.text)
                }
                .padding(.vertical, 4)
            }

            Divider()

            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    sendMessage()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Ride Chat")
        .onAppear {
            viewModel.startListening(rideId: ride.id)
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // Send Message

    private func sendMessage() {
        RideService.shared.sendMessage(
            rideId: ride.id,
            text: messageText,
            senderName: currentUserName
        )

        messageText = ""
    }
}
