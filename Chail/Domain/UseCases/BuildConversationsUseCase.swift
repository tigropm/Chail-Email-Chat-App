import Foundation

/// Gruppiert eine Liste von MailMessage-Objekten nach Gesprächspartner
/// und erzeugt daraus eine Liste von Conversation-Objekten.
///
/// Filterlogik:
///  - Eigene Adresse (Konto) wird als "ich" behandelt
///  - Der "andere" ist der erste externe Empfänger bzw. der Absender
///  - Gruppen-Mails (> 1 externer Empfänger) bilden eine eigene Gruppe
struct BuildConversationsUseCase {

    let account: MailAccount

    func execute(messages: [MailMessage]) -> [Conversation] {
        var buckets: [String: [MailMessage]] = [:]

        for message in messages {
            let key = conversationKey(for: message)
            buckets[key, default: []].append(message)
        }

        return buckets.map { (key, msgs) in
            let sorted  = msgs.sorted { $0.date < $1.date }
            let contact = contactAddress(for: sorted.first!, key: key)
            return Conversation(
                id:        key,
                accountId: account.id,
                contact:   contact,
                messages:  sorted
            )
        }.sorted()
    }

    // MARK: - Private

    /// Eindeutiger Schlüssel = normalisierte E-Mail des Gesprächspartners.
    /// Bei Gruppen-Mails: kommagetrennte, sortierte Liste aller Empfänger.
    private func conversationKey(for message: MailMessage) -> String {
        if message.isSent {
            // Gesendete Mail: Empfänger sind die "anderen"
            let externalRecipients = message.to
                .map(\.email)
                .filter { $0 != account.emailAddress }
                .sorted()
            if externalRecipients.count == 1 {
                return externalRecipients[0]
            } else {
                return externalRecipients.joined(separator: ",")
            }
        } else {
            // Empfangene Mail: Absender ist der "andere"
            return message.from.email
        }
    }

    private func contactAddress(for message: MailMessage, key: String) -> ContactAddress {
        if message.isSent {
            return message.to.first(where: { $0.email == key })
                ?? ContactAddress(email: key)
        } else {
            return message.from
        }
    }
}
