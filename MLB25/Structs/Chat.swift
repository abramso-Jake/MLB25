//
//  Chat.swift
//  MLB25
//
//  Created by Jake Abramson on 4/19/26.
//

import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: MessageRole
    let text: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

enum MessageRole: String, Codable, Hashable {
    case user
    case assistant
    case system
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
}

struct ChatResponse: Codable {
    let reply: String
}
