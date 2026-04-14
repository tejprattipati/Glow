import Foundation
import SwiftData

// MARK: - Chat Message Role
enum ChatRole: String, Codable {
    case user      = "user"
    case assistant = "assistant"
    case system    = "system"
}

// MARK: - Chat Message
@Model
final class ChatMessage {
    var id: UUID
    var role: String               // ChatRole.rawValue
    var content: String
    var timestamp: Date
    var isError: Bool

    @Relationship(deleteRule: .nullify)
    var thread: ChatThread?

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        isError: Bool = false
    ) {
        self.id = id
        self.role = role.rawValue
        self.content = content
        self.timestamp = Date()
        self.isError = isError
    }

    var chatRole: ChatRole { ChatRole(rawValue: role) ?? .user }
    var isUser: Bool { chatRole == .user }
    var isAssistant: Bool { chatRole == .assistant }
}

// MARK: - Chat Thread
@Model
final class ChatThread {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var relatedWorkoutSessionId: UUID?  // optional link to a session
    var contextSummary: String          // brief description of what this chat is about

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread)
    var messages: [ChatMessage]

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        relatedWorkoutSessionId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
        self.relatedWorkoutSessionId = relatedWorkoutSessionId
        self.contextSummary = ""
        self.messages = []
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    var lastMessage: ChatMessage? {
        sortedMessages.last
    }

    var previewText: String {
        lastMessage?.content.prefix(80).description ?? "No messages yet"
    }

    var messageCount: Int { messages.count }
}
