//
//  ContentView.swift
//  Commuvia
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {

    @StateObject private var authViewModel = AuthViewModel()

    @State private var showTerms = false
    @State private var termsChecked = false
    @State private var isCheckingTerms = false

    var body: some View {
        ZStack {
            Group {
                if !authViewModel.isAuthenticated {
                    AuthView(viewModel: authViewModel)
                        .onAppear {
                            resetTermsState()
                            SafetyState.shared.stop()
                        }

                } else if !authViewModel.isEmailVerified {
                    EmailVerificationView(
                        onRefresh: {
                            authViewModel.refreshEmailVerification()
                            // re-check terms after reload (some users verify and return)
                            checkTerms()
                        },
                        onResend: {
                            AuthService.shared.sendEmailVerification()
                        }
                    )
                    .onAppear {
                        // Authenticated session exists; start safety listeners early
                        SafetyState.shared.start()
                        checkTerms()
                    }

                } else {
                    // Authenticated + verified: must accept terms
                    if termsChecked && !showTerms {
                        RideListView(
                            authViewModel: authViewModel,
                            onSignOut: {
                                authViewModel.signOut()
                                resetTermsState()
                                SafetyState.shared.stop()
                            }
                        )
                        .onAppear {
                            // Keep safety listeners active for instant block/report filtering
                            SafetyState.shared.start()
                            checkTerms()
                        }

                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        }
                        .onAppear {
                            SafetyState.shared.start()
                            checkTerms()
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
                        termsChecked = true

                        // refresh the cached value (optional but consistent)
                        authViewModel.refreshTermsStatus()
                    }
                )
                .padding()
            }
        }
        // If auth status changes (login/logout), keep state consistent
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                SafetyState.shared.start()
                checkTerms()
            } else {
                resetTermsState()
                SafetyState.shared.stop()
            }
        }
        // If email becomes verified, re-check terms and proceed
        .onChange(of: authViewModel.isEmailVerified) { _, verified in
            if verified {
                checkTerms()
            }
        }
    }

    // MARK: - Helpers

    private func resetTermsState() {
        showTerms = false
        termsChecked = false
        isCheckingTerms = false
    }

    private func checkTerms() {
        guard Auth.auth().currentUser != nil else {
            resetTermsState()
            return
        }

        guard !isCheckingTerms else { return }
        isCheckingTerms = true

        AuthService.shared.hasAcceptedTerms { accepted in
            DispatchQueue.main.async {
                self.isCheckingTerms = false
                self.termsChecked = true
                self.showTerms = !accepted
            }
        }
    }
}
