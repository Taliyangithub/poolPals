//
//  RideMessage.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-01-26.
//


import Foundation

struct RideMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
}
