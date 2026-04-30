//
//  ChatViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/19/26.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: "Ask me anything baseball-related."
        )
    ]

    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String = ""

//    private let backendURLString = "http://localhost:3000/chat"
    private let backendURLString = "https://backend-o1ny.onrender.com/chat"


    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        errorMessage = ""

        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        inputText = ""

        isLoading = true
        defer { isLoading = false }

        do {
            let replyText = try await fetchAssistantReply()
            let assistantMessage = ChatMessage(role: .assistant, text: replyText)
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchAssistantReply() async throws -> String {
        guard let url = URL(string: backendURLString) else {
            throw ChatError.invalidURL
        }
        print("CHAT URL:", backendURLString)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(messages: messages)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
    
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let serverMessage = String(data: data, encoding: .utf8), !serverMessage.isEmpty {
                throw ChatError.serverError(serverMessage)
            }
            throw ChatError.serverError("Server returned status code \(httpResponse.statusCode).")
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.reply
    }
}

enum ChatError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let message):
            return message
        }
    }
}
