import Foundation

// MARK: - LLM Service Protocol
protocol LLMService {
    func sendMessage(
        messages: [LLMMessage],
        systemPrompt: String?,
        maxTokens: Int
    ) async throws -> String
}

// MARK: - LLM Message
struct LLMMessage: Codable {
    let role: String
    let content: String
}

// MARK: - LLM Errors
enum LLMError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case rateLimited
    case serverError(Int, String)
    case decodingError
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:        return "Invalid API key. Check Settings."
        case .networkError(let m):  return "Network error: \(m)"
        case .rateLimited:          return "Rate limited. Please wait a moment."
        case .serverError(let c, let m): return "Server error \(c): \(m)"
        case .decodingError:        return "Could not parse response."
        case .emptyResponse:        return "Empty response from API."
        case .timeout:              return "Request timed out."
        }
    }
}
