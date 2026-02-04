//
//  AuthViewModel.swift
//  Commuvia
//

import Foundation
import FirebaseAuth
import Combine

final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var currentUserName: String?
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        observeAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func observeAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user {
                    self?.isAuthenticated = true
                    self?.isEmailVerified = user.isEmailVerified
                    self?.loadCurrentUserProfile()
                } else {
                    self?.isAuthenticated = false
                    self?.isEmailVerified = false
                    self?.currentUserName = nil
                }
            }
        }
    }

    func refreshEmailVerification() {
        Auth.auth().currentUser?.reload { [weak self] _ in
            DispatchQueue.main.async {
                self?.isEmailVerified =
                    Auth.auth().currentUser?.isEmailVerified ?? false
            }
        }
    }

    func signUp(email: String, password: String, name: String) {
        AuthService.shared.signUp(email: email, password: password, name: name) { [weak self] result in
            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        AuthService.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadCurrentUserProfile() {
        AuthService.shared.fetchCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                if case let .success(user) = result {
                    self?.currentUserName = user.name
                }
            }
        }
    }
    
    func changePassword(
        currentPassword: String,
        newPassword: String
    ) {
        AuthService.shared.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.errorMessage = "Password updated successfully."
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func forgotPassword(email: String) {
        AuthService.shared.sendPasswordReset(email: email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.errorMessage =
                        "Password reset email sent. If you reset your password, your email will be verified automatically."
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }



    func signOut() {
        try? AuthService.shared.signOut()
    }
}
