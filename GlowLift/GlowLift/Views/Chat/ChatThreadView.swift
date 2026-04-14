import SwiftUI
import SwiftData

struct ChatThreadView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var thread: ChatThread
    let recentSessions: [WorkoutSession]

    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil

    @FocusState private var inputFocused: Bool

    private let claude = ClaudeService(model: "claude-opus-4-6")

    private var sortedMessages: [ChatMessage] {
        thread.sortedMessages
    }

    var body: some View {
        ZStack {
            GlowTheme.Colors.gradientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Message list
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: GlowTheme.Spacing.sm) {
                            if sortedMessages.isEmpty {
                                welcomeMessage
                            }
                            ForEach(sortedMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isSending {
                                typingIndicator
                            }
                            if let err = errorMessage {
                                errorBanner(err)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, GlowTheme.Spacing.md)
                        .padding(.top, GlowTheme.Spacing.md)
                        .padding(.bottom, 80)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: sortedMessages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Input bar
                inputBar
            }
        }
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Rename") { renameThread() }
                    Button("Clear History", role: .destructive) { clearHistory() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(GlowTheme.Colors.purple)
                }
            }
        }
    }

    // MARK: - Welcome
    private var welcomeMessage: some View {
        VStack(spacing: GlowTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(GlowTheme.Colors.purple.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(GlowTheme.Colors.purpleLight)
            }
            .glowEffect(radius: 16)
            Text("GlowLift AI")
                .font(GlowTheme.Fonts.headline())
                .foregroundColor(.white)
            Text("Ask me about your training, progression, rest times, or anything gym-related.")
                .font(GlowTheme.Fonts.body())
                .foregroundColor(GlowTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Suggested prompts
            VStack(spacing: GlowTheme.Spacing.sm) {
                let prompts = [
                    "What should I do next workout?",
                    "How do I progress on bench press?",
                    "What's a good rest time for compound lifts?"
                ]
                ForEach(prompts, id: \.self) { prompt in
                    Button(action: { inputText = prompt }) {
                        Text(prompt)
                            .font(GlowTheme.Fonts.caption(13))
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                                    .fill(GlowTheme.Colors.surfaceElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                                            .stroke(GlowTheme.Colors.purple.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(.vertical, GlowTheme.Spacing.xl)
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: GlowTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(GlowTheme.Colors.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GlowTheme.Colors.purple)
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(GlowTheme.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                        .animation(
                            Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: isSending
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                    .fill(GlowTheme.Colors.surfaceElevated)
            )
            Spacer()
        }
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(GlowTheme.Colors.error)
            Text(message)
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.error)
            Spacer()
            Button("Dismiss") { errorMessage = nil }
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.textTertiary)
        }
        .padding(GlowTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                .fill(GlowTheme.Colors.error.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                        .stroke(GlowTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: GlowTheme.Spacing.sm) {
            TextField("Ask your AI coach...", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .font(GlowTheme.Fonts.body())
                .foregroundColor(.white)
                .focused($inputFocused)
                .padding(.horizontal, GlowTheme.Spacing.md)
                .padding(.vertical, GlowTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                        .fill(GlowTheme.Colors.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                                .stroke(inputFocused ? GlowTheme.Colors.purple.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )

            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
                              ? GlowTheme.Colors.surfaceElevated
                              : GlowTheme.Colors.gradientPurple)
                        .frame(width: 40, height: 40)
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: GlowTheme.Colors.purple))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? GlowTheme.Colors.textMuted : .white)
                    }
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, GlowTheme.Spacing.md)
        .padding(.vertical, GlowTheme.Spacing.sm)
        .background(GlowTheme.Colors.surface)
        .overlay(alignment: .top) {
            Divider().background(GlowTheme.Colors.textMuted.opacity(0.2))
        }
    }

    // MARK: - Send
    private func sendMessage() {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty && !isSending else { return }

        inputText = ""
        errorMessage = nil
        isSending = true
        inputFocused = false

        // Persist user message
        let userMsg = ChatMessage(role: .user, content: userText)
        userMsg.thread = thread
        thread.messages.append(userMsg)
        thread.updatedAt = Date()
        try? context.save()

        // Build context
        let systemPrompt = GymContextBuilder.systemPrompt(recentSessions: recentSessions)
        let llmMessages = thread.sortedMessages
            .filter { !$0.isError }
            .map { LLMMessage(role: $0.chatRole.rawValue, content: $0.content) }

        Task {
            do {
                let reply = try await claude.sendMessage(
                    messages: llmMessages,
                    systemPrompt: systemPrompt,
                    maxTokens: 1024
                )
                await MainActor.run {
                    let assistantMsg = ChatMessage(role: .assistant, content: reply)
                    assistantMsg.thread = thread
                    thread.messages.append(assistantMsg)
                    thread.updatedAt = Date()

                    // Auto-title from first exchange
                    if thread.messages.count == 2 {
                        thread.title = String(userText.prefix(40))
                    }
                    try? context.save()
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LLMError)?.errorDescription ?? error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }

    private func renameThread() {
        // Title auto-updates from first message; could add an alert here for manual rename
    }

    private func clearHistory() {
        for msg in thread.messages { context.delete(msg) }
        thread.messages = []
        try? context.save()
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: GlowTheme.Spacing.sm) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                // Avatar
                ZStack {
                    Circle()
                        .fill(GlowTheme.Colors.purple.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GlowTheme.Colors.purpleLight)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(GlowTheme.Fonts.body())
                    .foregroundColor(message.isUser ? .white : GlowTheme.Colors.textPrimary)
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.vertical, GlowTheme.Spacing.sm)
                    .background(bubbleBackground)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(GlowTheme.Fonts.caption(10))
                    .foregroundColor(GlowTheme.Colors.textMuted)
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isUser {
            RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                .fill(GlowTheme.Colors.gradientPurple)
                .shadow(color: GlowTheme.Colors.purple.opacity(0.3), radius: 8)
        } else {
            RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                .fill(GlowTheme.Colors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.lg)
                        .stroke(GlowTheme.Colors.purple.opacity(0.15), lineWidth: 1)
                )
        }
    }
}
