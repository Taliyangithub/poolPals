//
//  ForgotPasswordView.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-04.
//


import SwiftUI

struct ForgotPasswordView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        Form {
            Section {
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Button("Send Reset Email") {
                authViewModel.forgotPassword(email: email)
                dismiss()
            }
            .disabled(email.isEmpty)

            Text(
                "A password reset email will be sent to your inbox. If you don’t see it within a few minutes, please check your spam or junk folder. Resetting your password will also verify your email address."
            )
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .navigationTitle("Forgot Password")
    }
}
