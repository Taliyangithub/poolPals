//
//  TermsAcceptanceView.swift
//  Commuvia
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TermsAcceptanceView: View {

    let onAccepted: () -> Void

    @State private var accepted = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Commuvia Community Guidelines")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                guideline("No harassment, hate speech, threats, or abusive behavior")
                guideline("No sexual or violent content")
                guideline("No impersonation or spam")
                guideline("Violations may result in permanent account removal")
            }

            Text("Reported content is reviewed and acted upon within 24 hours.")
                .font(.footnote)
                .foregroundColor(.secondary)

            Divider()

            Toggle(
                "I agree to the Terms and Safety Guidelines",
                isOn: $accepted
            )

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            HStack {
                Spacer()

                Button("Continue") {
                    saveAcceptance()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!accepted)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: 480)
        .background(.thinMaterial)
        .cornerRadius(14)
    }

    //Helpers

    private func guideline(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.body)
    }

    //Save Acceptance

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
                    onAccepted()   // ⬅️ THIS dismisses the overlay
                }
            }
    }
}
