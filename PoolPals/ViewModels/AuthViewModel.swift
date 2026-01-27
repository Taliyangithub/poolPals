//
//  AuthViewModel.swift
//  PoolPals
//

import Foundation
import FirebaseAuth
import Combine

final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserName: String?

    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        observeAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Observe Auth State

    private func observeAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if user != nil {
                    self?.isAuthenticated = true
                    self?.loadCurrentUserProfile()
                } else {
                    self?.isAuthenticated = false
                    self?.currentUserName = nil
                }
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) {
        AuthService.shared.signUp(
            email: email,
            password: password,
            name: name
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.errorMessage = nil
                    self?.loadCurrentUserProfile()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) {
        AuthService.shared.signIn(
            email: email,
            password: password
        ) { [weak self] result in
            DispatchQueue.main.async {
                if case let .failure(error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Load Current User Profile

    private func loadCurrentUserProfile() {
        AuthService.shared.fetchCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUserName = user.name
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
