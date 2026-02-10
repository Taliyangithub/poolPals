import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {

    let onRefresh: () -> Void
    let onResend: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Verify Your Email")
                .font(.title2)
                .fontWeight(.semibold)

            Text("""
We have sent a verification email to your registered email address.
Please verify your email to continue using the app.
""")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("I Have Verified My Email") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)

            Button("Resend Verification Email") {
                onResend()
            }
            .buttonStyle(.bordered)

            Divider()
                .padding(.vertical, 8)

            Button(role: .destructive) {
                try? Auth.auth().signOut()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
