import SwiftUI

struct ChangePasswordView: View {

    @ObservedObject var authViewModel: AuthViewModel

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section("Change Password") {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)

                Button("Update Password") {
                    updatePassword()
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if let successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
            }
        }
        .navigationTitle("Change Password")
    }

    private func updatePassword() {
        authViewModel.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        ) { result in
            switch result {
            case .success:
                successMessage = "Password updated successfully"
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
                successMessage = nil
            }
        }
    }
}

