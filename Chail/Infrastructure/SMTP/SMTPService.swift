import Foundation

/// Sendet E-Mails via SMTP.
/// Implementierung via MailCore2 MCOSMTPSession.
final class SMTPService {

    private let keychain: KeychainService

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    func send(message: MailMessage, account: MailAccount) async throws {
        let password = try keychain.load(key: account.keychainKey)
        _ = password

        /*
         Echter SMTP-Ablauf mit MailCore2:

         let session = MCOSMTPSession()
         session.hostname       = account.smtpHost
         session.port           = UInt32(account.smtpPort)
         session.username       = account.username
         session.password       = password
         session.connectionType = account.smtpUseSSL ? .TLS : .startTLS

         let builder = MCOMessageBuilder()
         builder.header.from    = MCOAddress(displayName: account.displayName, mailbox: account.emailAddress)
         builder.header.to      = message.to.map { MCOAddress(displayName: $0.displayName, mailbox: $0.email) }
         builder.header.subject = message.subject
         builder.textBody       = message.bodyPlain
         builder.htmlBody       = message.bodyHTML

         if let replyTo = message.inReplyToId {
             builder.header.inReplyTo = replyTo
         }

         let rfc822Data = builder.data()
         let op         = session.sendOperation(with: rfc822Data)
         try await op.start()
         */
    }

    func validateConnection(account: MailAccount) async throws {
        // TODO: SMTP EHLO + AUTH testen
    }
}
