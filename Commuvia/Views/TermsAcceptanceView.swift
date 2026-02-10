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
        VStack(alignment: .leading, spacing: 16) {

            Text("Commuvia Terms & Community Safety")
                .font(.headline)

            Text("""
Commuvia is a community ride-sharing helper. You must follow these rules:

• No harassment, hate speech, threats, or abusive behavior
• No sexual content, violent content, or content encouraging harm
• No impersonation, scams, or spam
• Do not share private information (phone numbers, addresses) in chat
• Violations may result in content removal, ride removal, and permanent account removal

You can report rides or messages, and you can block users at any time.
Reports and safety issues are reviewed and acted upon within 24 hours.
""")
            .font(.footnote)
            .foregroundColor(.secondary)

            Divider()

            Toggle("I agree to the Terms and Safety Guidelines", isOn: $accepted)

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
        .frame(maxWidth: 520)
        .background(.thinMaterial)
        .cornerRadius(14)
    }

    private func saveAcceptance() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(
                [
                    "termsAccepted": true,
                    "termsAcceptedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            ) { err in
                if let err {
                    error = err.localizedDescription
                } else {
                    onAccepted()
                }
            }
    }

}
