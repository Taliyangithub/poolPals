import SwiftUI

struct ContentView: View {

    @StateObject private var authViewModel = AuthViewModel()
    @State private var showTerms = false

    var body: some View {
        ZStack {

            // MAIN FLOW
            Group {
                if !authViewModel.isAuthenticated {
                    AuthView(viewModel: authViewModel)

                } else if !authViewModel.isEmailVerified {
                    EmailVerificationView(
                        onRefresh: {
                            authViewModel.refreshEmailVerification()
                        },
                        onResend: {
                            AuthService.shared.sendEmailVerification()
                        }
                    )

                } else {
                    RideListView(
                        authViewModel: authViewModel,
                        onSignOut: authViewModel.signOut
                    )
                    .onAppear {
                        AuthService.shared.hasAcceptedTerms { accepted in
                            DispatchQueue.main.async {
                                showTerms = !accepted
                            }
                        }
                    }
                }
            }

            if showTerms {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()

                TermsAcceptanceView(
                    onAccepted: {
                        showTerms = false
                    }
                )
                .padding()
            }

        }
    }
}
