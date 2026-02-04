//
//  EmailVerificationView.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-04.
//


import SwiftUI

struct EmailVerificationView: View {

    let onRefresh: () -> Void
    let onResend: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            Text("Verify your email")
                .font(.title2)
                .bold()

            Text("""
            Please verify your email address before using Commuvia.

            Check your inbox and spam folder.
            """)
            .multilineTextAlignment(.center)

            Button("I have verified my email") {
                onRefresh()
            }

            Button("Resend verification email") {
                onResend()
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
}
