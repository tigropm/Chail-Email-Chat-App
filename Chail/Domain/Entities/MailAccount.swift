import Foundation

/// Repräsentiert ein IMAP/SMTP-Konto.
/// Passwörter werden NICHT hier gespeichert — ausschließlich im Keychain.
struct MailAccount: Identifiable, Codable, Hashable, Sendable {

    let id: UUID
    var displayName: String
    var emailAddress: String

    // IMAP
    var imapHost: String
    var imapPort: Int       // Standard: 993
    var imapUseSSL: Bool    // true = direktes TLS, false = STARTTLS

    // SMTP
    var smtpHost: String
    var smtpPort: Int       // 587 (STARTTLS) oder 465 (TLS)
    var smtpUseSSL: Bool

    var username: String    // häufig == emailAddress

    var lastSyncDate: Date?
    var isActive: Bool

    // MARK: - Init

    init(
        id: UUID = UUID(),
        displayName: String,
        emailAddress: String,
        imapHost: String,
        imapPort: Int = 993,
        imapUseSSL: Bool = true,
        smtpHost: String,
        smtpPort: Int = 587,
        smtpUseSSL: Bool = false,
        username: String,
        isActive: Bool = true
    ) {
        self.id           = id
        self.displayName  = displayName
        self.emailAddress = emailAddress.lowercased().trimmingCharacters(in: .whitespaces)
        self.imapHost     = imapHost
        self.imapPort     = imapPort
        self.imapUseSSL   = imapUseSSL
        self.smtpHost     = smtpHost
        self.smtpPort     = smtpPort
        self.smtpUseSSL   = smtpUseSSL
        self.username     = username
        self.isActive     = isActive
    }

    /// Keychain-Schlüssel für das Passwort dieses Kontos
    var keychainKey: String { "chail.imap.\(id.uuidString)" }
}
