//
//  ChatListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/19/26.
//

import SwiftUI

struct ChatListView: View {
    @State private var chatVM = ChatViewModel()
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chatVM.messages) { message in
                                HStack {
                                    if message.role == .assistant {
                                        messageBubble(message, isUser: false)
                                        Spacer(minLength: 40)
                                    } else {
                                        Spacer(minLength: 40)
                                        messageBubble(message, isUser: true)
                                    }
                                }
                                .id(message.id)
                            }

                            if chatVM.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatVM.messages.count) {
                        if let lastID = chatVM.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                if !chatVM.errorMessage.isEmpty {
                    Text(chatVM.errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer()

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Ask a baseball question...", text: $chatVM.inputText)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.trailing, 30)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray, lineWidth: 1)
                        )
                        .overlay{
                            HStack {
                                Spacer()
                                if !chatVM.inputText.isEmpty {
                                    Button {
                                        chatVM.inputText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        }

                    Button {
                        Task {
                            await chatVM.sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                    }
                    .disabled(chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatVM.isLoading)
                }
                .padding()
            }
            .navigationTitle("Baseball AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "chevron.left", role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage, isUser: Bool) -> some View {
        Text(message.text)
            .padding(12)
            .background(isUser ? Color.blue.opacity(0.18) : Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }
}

#Preview {
    NavigationStack{
        ChatListView()
    }
}
