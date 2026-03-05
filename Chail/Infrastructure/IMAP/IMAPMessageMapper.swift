import Foundation

/// Konvertiert MailCore2-Rohobjekte (MCOIMAPMessage) in domäneninterne MailMessage-Objekte.
/// Diese Klasse isoliert die MailCore2-Abhängigkeit vollständig von der Domain-Schicht.
enum IMAPMessageMapper {

    /*
     Beispielimplementierung mit MailCore2:

     static func map(_ raw: MCOIMAPMessage, accountId: UUID, folder: String) -> MailMessage? {
         guard let header = raw.header else { return nil }

         let messageId = header.messageID ?? UUID().uuidString
         let from      = address(from: header.from)
         let toList    = addresses(from: header.to)
         let ccList    = addresses(from: header.cc)

         return MailMessage(
             id:          messageId,
             uid:         raw.uid,
             accountId:   accountId,
             folderName:  folder,
             from:        from,
             to:          toList,
             cc:          ccList,
             subject:     header.subject ?? "(kein Betreff)",
             date:        header.date ?? Date(),
             bodyPlain:   nil,  // wird lazy geladen
             bodyHTML:    nil,
             attachments: parts(from: raw.mainPart()),
             isRead:      raw.flags.contains(.seen),
             isSent:      folder.lowercased().contains("sent"),
             isStarred:   raw.flags.contains(.flagged),
             inReplyToId: header.inReplyTo,
             references:  header.references as? [String] ?? []
         )
     }

     private static func address(from mcoAddr: MCOAddress?) -> ContactAddress {
         ContactAddress(
             displayName: mcoAddr?.displayName,
             email:       mcoAddr?.mailbox ?? ""
         )
     }

     private static func addresses(from arr: [MCOAddress]?) -> [ContactAddress] {
         (arr ?? []).map { address(from: $0) }
     }

     private static func parts(from part: MCOAbstractMessagePart?) -> [MailAttachment] {
         // Rekursiv durch Multipart-Struktur iterieren und Attachments extrahieren
         []
     }
     */

    /// Stub-Mapper für Testzwecke
    static func map(
        uid: UInt32,
        messageId: String,
        fromEmail: String,
        fromName: String?,
        toEmail: String,
        subject: String,
        body: String,
        date: Date,
        accountId: UUID,
        folder: String
    ) -> MailMessage {
        MailMessage(
            id:          messageId,
            uid:         uid,
            accountId:   accountId,
            folderName:  folder,
            from:        ContactAddress(displayName: fromName, email: fromEmail),
            to:          [ContactAddress(email: toEmail)],
            cc:          [],
            subject:     subject,
            date:        date,
            bodyPlain:   body,
            bodyHTML:    nil,
            attachments: [],
            isRead:      false,
            isSent:      folder.lowercased().contains("sent"),
            isStarred:   false,
            inReplyToId: nil,
            references:  []
        )
    }
}
