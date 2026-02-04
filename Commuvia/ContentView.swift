import SwiftUI

struct ContentView: View {

    @StateObject private var authViewModel = AuthViewModel()
    @State private var showTerms = false

    var body: some View {
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
                .sheet(isPresented: $showTerms) {
                    TermsAcceptanceView()
                }
            }
        }
    }
}
