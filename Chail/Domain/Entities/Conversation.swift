import Foundation

/// Alle E-Mails zwischen dem Nutzer und einem bestimmten Kontakt.
/// Das ist die zentrale Abstraktion von Chail.
struct Conversation: Identifiable, Hashable {

    /// ID = normalisierte E-Mail-Adresse des Gesprächspartners
    let id: String
    let accountId: UUID
    var contact: ContactAddress
    /// Chronologisch aufsteigend sortiert
    var messages: [MailMessage]

    // MARK: - Computed

    var lastMessage: MailMessage? { messages.last }

    var unreadCount: Int {
        messages.filter { !$0.isRead && !$0.isSent }.count
    }

    var hasUnread: Bool { unreadCount > 0 }

    var lastActivity: Date {
        lastMessage?.date ?? .distantPast
    }

    /// Kurzvorschau für die Konversationsliste
    var preview: String {
        guard let last = lastMessage else { return "" }
        let prefix = last.isSent ? "Du: " : ""
        return prefix + last.preview
    }
}

// MARK: - Comparable für Sortierung (neueste zuerst)

extension Conversation: Comparable {
    static func < (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.lastActivity > rhs.lastActivity
    }
}
