import SwiftUI

struct ChangePasswordView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    var body: some View {
        Form {

            Section(header: Text("Current Password")) {
                SecureField("Current password", text: $currentPassword)
            }

            Section(header: Text("New Password")) {
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }

            if let localError {
                Text(localError)
                    .foregroundColor(.red)
            }

            Button("Update Password") {
                submit()
            }
            .disabled(!isValid)
        }
        .navigationTitle("Change Password")
    }

    private var isValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    private func submit() {
        guard newPassword == confirmPassword else {
            localError = "Passwords do not match."
            return
        }

        authViewModel.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        )

        dismiss()
    }
}
