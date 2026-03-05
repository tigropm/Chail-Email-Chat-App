import Foundation

/// Eine einzelne E-Mail, normalisiert aus den IMAP-Rohdaten.
struct MailMessage: Identifiable, Hashable, Sendable {

    // MARK: - Identifikation

    /// RFC 2822 Message-ID Header (global eindeutig)
    let id: String
    /// IMAP UID innerhalb des Ordners
    let uid: UInt32
    let accountId: UUID
    let folderName: String

    // MARK: - Header

    var from: ContactAddress
    var to: [ContactAddress]
    var cc: [ContactAddress]
    var subject: String
    var date: Date

    // MARK: - Body

    var bodyPlain: String?
    var bodyHTML: String?

    // MARK: - Anhänge

    var attachments: [MailAttachment]

    // MARK: - Flags & Metadaten

    var isRead: Bool
    /// true = Mail befindet sich im Sent-Ordner dieses Kontos
    var isSent: Bool
    var isStarred: Bool

    // MARK: - Threading

    var inReplyToId: String?
    var references: [String]

    // MARK: - Computed

    /// Kurzvorschau für die Konversationsliste
    var preview: String {
        let source = bodyPlain ?? bodyHTML?.strippedHTML ?? ""
        return String(source.prefix(120))
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    var hasAttachments: Bool { !attachments.isEmpty }
}

// MARK: - String HTML-Strip Helper (einfach, kein Parser)

private extension String {
    var strippedHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
