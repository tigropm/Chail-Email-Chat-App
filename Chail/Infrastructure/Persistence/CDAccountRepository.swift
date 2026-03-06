import Foundation
import CoreData
import Combine

final class CDAccountRepository: AccountRepositoryProtocol, ObservableObject {

    private let stack: CoreDataStack
    private let subject = CurrentValueSubject<[MailAccount], Never>([])

    var accounts: AnyPublisher<[MailAccount], Never> {
        subject.eraseToAnyPublisher()
    }

    init(stack: CoreDataStack) {
        self.stack = stack
        // TODO: NSFetchedResultsController laden und subject befüllen
    }

    func save(account: MailAccount) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            // TODO: CDAccount erstellen/aktualisieren
            _ = account
            try context.save()
        }
        // Subject aktualisieren
        var current = subject.value.filter { $0.id != account.id }
        current.append(account)
        subject.send(current.sorted { $0.displayName < $1.displayName })
    }

    func delete(accountId: UUID) async throws {
        let context = stack.newBackgroundContext()
        try await context.perform {
            // TODO: CDAccount löschen
            try context.save()
        }
        subject.send(subject.value.filter { $0.id != accountId })
    }

    func account(id: UUID) async throws -> MailAccount? {
        subject.value.first { $0.id == id }
    }

    func updateSyncDate(_ date: Date, for accountId: UUID) async throws {
        var updated = subject.value
        if let idx = updated.firstIndex(where: { $0.id == accountId }) {
            updated[idx].lastSyncDate = date
            subject.send(updated)
        }
    }
}
