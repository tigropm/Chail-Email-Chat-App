import Foundation
import Combine

/// Abstraktion für den Zugriff auf lokal persistierte E-Mails.
protocol MailRepositoryProtocol: AnyObject {

    // MARK: - Lesen

    func conversations(for accountId: UUID) -> AnyPublisher<[Conversation], Never>
    func messages(for conversationId: String, accountId: UUID) async throws -> [MailMessage]
    func message(id: String) async throws -> MailMessage?
    func highestUID(in folder: String, accountId: UUID) async -> UInt32

    // MARK: - Schreiben

    func save(messages: [MailMessage]) async throws
    func markAsRead(messageIds: [String]) async throws
    func delete(messageIds: [String]) async throws
}
