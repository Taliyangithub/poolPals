import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {

    let onRefresh: () -> Void
    let onResend: () -> Void

    @State private var message =
        "Please verify your email address to continue."

    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Verify Your Email")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("I’ve Verified My Email") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)

            Button("Resend Verification Email") {
                onResend()
                message = "Verification email sent. Please check your inbox and spam folder."
            }
            .buttonStyle(.bordered)

            Divider()
                .padding(.vertical, 8)

            //LOG OUT BUTTON (IMPORTANT)
            Button(role: .destructive) {
                try? Auth.auth().signOut()
            } label: {
                Text("Log Out and Sign In Again")
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
