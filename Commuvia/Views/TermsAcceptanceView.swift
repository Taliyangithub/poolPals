//
//  TermsAcceptanceView.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-04.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TermsAcceptanceView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var accepted = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {

            ScrollView {
                Text("""
                Commuvia Community Guidelines

                • No harassment, hate speech, threats, or abusive behavior
                • No sexual or violent content
                • No impersonation or spam
                • Violations may result in permanent account removal

                Reported content is reviewed within 24 hours.
                """)
                .font(.body)
            }
            
            Text("All reports are reviewed and acted upon within 24 hours.")
                .font(.footnote)
                .foregroundColor(.secondary)


            Toggle("I agree to the Terms and Safety Guidelines", isOn: $accepted)

            if let error {
                Text(error).foregroundColor(.red)
            }

            Button("Continue") {
                saveAcceptance()
            }
            .disabled(!accepted)
        }
        .padding()
    }

    private func saveAcceptance() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData([
                "termsAccepted": true,
                "termsAcceptedAt": FieldValue.serverTimestamp()
            ]) { err in
                if let err {
                    error = err.localizedDescription
                } else {
                    dismiss()
                }
            }
    }
}
