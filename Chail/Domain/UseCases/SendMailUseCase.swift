import Foundation

struct SendMailUseCase {

    let smtpService: SMTPService
    let mailRepository: any MailRepositoryProtocol

    /// Sendet eine E-Mail und speichert sie lokal als gesendete Nachricht.
    func execute(draft: MailDraft, account: MailAccount) async throws {
        let message = try draft.buildMessage(from: account)
        try await smtpService.send(message: message, account: account)

        // Lokal als gesendete Mail speichern
        var sentMessage = message
        sentMessage = MailMessage(
            id:          message.id,
            uid:         0,
            accountId:   account.id,
            folderName:  "Sent",
            from:        ContactAddress(displayName: account.displayName, email: account.emailAddress),
            to:          message.to,
            cc:          message.cc,
            subject:     message.subject,
            date:        message.date,
            bodyPlain:   message.bodyPlain,
            bodyHTML:    message.bodyHTML,
            attachments: message.attachments,
            isRead:      true,
            isSent:      true,
            isStarred:   false,
            inReplyToId: message.inReplyToId,
            references:  message.references
        )
        try await mailRepository.save(messages: [sentMessage])
    }
}

// MARK: - MailDraft

/// Enthält alle Felder zum Erstellen einer ausgehenden Mail.
struct MailDraft {
    var to: [ContactAddress]
    var cc: [ContactAddress] = []
    var subject: String
    var bodyPlain: String
    var inReplyToId: String?
    var references: [String] = []
    var attachments: [MailAttachment] = []

    func buildMessage(from account: MailAccount) throws -> MailMessage {
        let messageId = "<\(UUID().uuidString)@\(account.emailAddress.emailDomain)>"
        return MailMessage(
            id:          messageId,
            uid:         0,
            accountId:   account.id,
            folderName:  "Sent",
            from:        ContactAddress(displayName: account.displayName, email: account.emailAddress),
            to:          to,
            cc:          cc,
            subject:     subject,
            date:        Date(),
            bodyPlain:   bodyPlain,
            bodyHTML:    bodyPlain.asSimpleHTML,
            attachments: attachments,
            isRead:      true,
            isSent:      true,
            isStarred:   false,
            inReplyToId: inReplyToId,
            references:  references
        )
    }
}

private extension String {
    var emailDomain: String {
        components(separatedBy: "@").last ?? "chail.app"
    }

    var asSimpleHTML: String {
        "<html><body><p>\(self.replacingOccurrences(of: "\n", with: "<br>"))</p></body></html>"
    }
}
