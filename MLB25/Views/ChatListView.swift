//
//  ChatListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/19/26.
//

import SwiftUI

struct ChatListView: View {
    @FocusState private var isInputFocused: Bool
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
                                .id("thinking-indicator")
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: chatVM.messages.last?.id) {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: chatVM.isLoading) {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }

                if !chatVM.errorMessage.isEmpty {
                    Text(chatVM.errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Ask a baseball question...", text: $chatVM.inputText, axis: .vertical)
                        .submitLabel(.done)
                        .onSubmit {
                            submitMessage()
                        }
                        .autocorrectionDisabled()
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .padding(.trailing, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray, lineWidth: 1)
                        )
                        .overlay {
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
                        submitMessage()
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
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("", systemImage: "chevron.left", role: .close) {
//                        dismiss()
//                    }
//                }
//            }
        }
    }
    private func submitMessage() {
        let trimmed = chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chatVM.isLoading else { return }

        isInputFocused = false

        Task {
            await chatVM.sendMessage()
        }
    }
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.async {
            if chatVM.isLoading {
                if animated {
                    withAnimation {
                        proxy.scrollTo("thinking-indicator", anchor: .bottom)
                    }
                } else {
                    proxy.scrollTo("thinking-indicator", anchor: .bottom)
                }
            } else if let lastID = chatVM.messages.last?.id {
                if animated {
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                } else {
                    proxy.scrollTo(lastID, anchor: .bottom)
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
