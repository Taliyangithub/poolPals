//
//  RideChatView.swift
//  Commuvia
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RideChatView: View {

    // MARK: - Inputs

    let ride: Ride
    let currentUserName: String

    // MARK: - State

    @StateObject private var viewModel = RideChatViewModel()
    @State private var messageText: String = ""

    @State private var showActionSheet = false
    @State private var selectedMessage: RideMessage?
    @State private var showReportConfirmation = false
    @State private var showBlockConfirmation = false

    // MARK: - Body

    var body: some View {
        VStack {

            List(viewModel.messages) { message in
                VStack(alignment: .leading, spacing: 4) {

                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(message.text)
                        .font(.body)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    guard message.senderId != Auth.auth().currentUser?.uid else { return }
                    selectedMessage = message
                    showActionSheet = true
                }
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
        .confirmationDialog(
            "Message Actions",
            isPresented: $showActionSheet,
            titleVisibility: .visible
        ) {
            Button("Report Message", role: .destructive) {
                showReportConfirmation = true
            }

            Button("Block User", role: .destructive) {
                showBlockConfirmation = true
            }

            Button("Cancel", role: .cancel) { }
        }
        .alert(
            "Report Message",
            isPresented: $showReportConfirmation
        ) {
            Button("Report", role: .destructive) {
                reportSelectedMessage()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This message will be reviewed and appropriate action will be taken within 24 hours.")
        }
        .alert(
            "Block User",
            isPresented: $showBlockConfirmation
        ) {
            Button("Block", role: .destructive) {
                blockSelectedUser()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Blocked users will no longer appear in your chat or ride activity.")
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        RideService.shared.sendMessage(
            rideId: ride.id,
            text: messageText,
            senderName: currentUserName
        )

        messageText = ""
    }

    private func reportSelectedMessage() {
        guard
            let message = selectedMessage,
            let reporterId = Auth.auth().currentUser?.uid
        else { return }

        Firestore.firestore()
            .collection("rides")
            .document(ride.id)
            .collection("messages")
            .document(message.id)
            .collection("reports")
            .addDocument(data: [
                "reportedBy": reporterId,
                "senderId": message.senderId,
                "reason": "Abusive or objectionable content",
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    private func blockSelectedUser() {
        guard let message = selectedMessage else { return }

        BlockService.shared.blockUser(
            blockedUserId: message.senderId,
            reason: "Abusive chat behavior"
        )

        // Instantly remove from UI
        viewModel.messages.removeAll {
            $0.senderId == message.senderId
        }
    }
}
