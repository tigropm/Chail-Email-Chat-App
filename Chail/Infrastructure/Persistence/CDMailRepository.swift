import Foundation
import CoreData
import Combine

/// CoreData-Implementierung des MailRepositoryProtocol.
final class CDMailRepository: MailRepositoryProtocol {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    // MARK: - Konversationen (Publisher)

    func conversations(for accountId: UUID) -> AnyPublisher<[Conversation], Never> {
        // In einer vollständigen Implementierung: NSFetchedResultsController + Combine
        // Hier vereinfachtes Publisher-Stub
        Just([]).eraseToAnyPublisher()
    }

    // MARK: - Nachrichten

    func messages(for conversationId: String, accountId: UUID) async throws -> [MailMessage] {
        // TODO: CoreData-Fetch nach from/to email == conversationId
        return []
    }

    func message(id: String) async throws -> MailMessage? {
        // TODO: CoreData-Fetch nach messageId
        return nil
    }

    func highestUID(in folder: String, accountId: UUID) async -> UInt32 {
        // TODO: CoreData MAX(uid) Abfrage
        return 0
    }

    // MARK: - Schreiben

    func save(messages: [MailMessage]) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            for message in messages {
                // TODO: CDMessage-Objekt erstellen/aktualisieren
                _ = message
            }
            try context.save()
        }
    }

    func markAsRead(messageIds: [String]) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            // TODO: isRead = true für alle messageIds setzen
            try context.save()
        }
    }

    func delete(messageIds: [String]) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            // TODO: CDMessage-Objekte löschen
            try context.save()
        }
    }
}
