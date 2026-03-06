import Foundation
import Combine

struct SearchMailsUseCase {

    let mailRepository: any MailRepositoryProtocol

    /// Durchsucht gespeicherte Konversationen nach dem Suchbegriff.
    /// Durchsucht: Kontaktname, E-Mail, Betreff, Body-Vorschau.
    func execute(query: String, accountId: UUID) -> AnyPublisher<[Conversation], Never> {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)

        return mailRepository.conversations(for: accountId)
            .map { conversations in
                guard !q.isEmpty else { return conversations }
                return conversations.filter { conv in
                    conv.contact.email.contains(q)
                    || (conv.contact.displayName?.lowercased().contains(q) ?? false)
                    || conv.messages.contains { msg in
                        msg.subject.lowercased().contains(q)
                        || (msg.bodyPlain?.lowercased().contains(q) ?? false)
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
