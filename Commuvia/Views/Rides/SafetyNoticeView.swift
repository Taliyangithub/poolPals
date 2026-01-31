//
//  SafetyNoticeView.swift
//  PoolPals
//
//  Created by Priya Taliyan on 2026-01-30.
//


import SwiftUI

struct SafetyNoticeView: View {

    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Safety Notice")
                .font(.title2)
                .fontWeight(.semibold)

            Text("""
PoolPals helps connect people for shared rides.

Always use your judgment when traveling with others.
Meet in public places and share your plans with someone you trust.
""")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("I Understand") {
                onAcknowledge()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
}
