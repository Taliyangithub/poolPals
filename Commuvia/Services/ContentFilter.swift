//
//  ContentFilter.swift
//  Commuvia
//
//  Created by Priya Taliyan on 2026-02-04.
//


import Foundation

enum ContentFilter {

    static let bannedWords: [String] = [
        "hate",
        "kill",
        "sex",
        "abuse",
        "harass"
    ]

    static func containsObjectionableContent(_ text: String) -> Bool {
        let lower = text.lowercased()
        return bannedWords.contains { lower.contains($0) }
    }
}
