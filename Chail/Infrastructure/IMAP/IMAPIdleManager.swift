import Foundation

/// Verwaltet IMAP IDLE-Verbindungen für Echtzeit-Benachrichtigungen.
///
/// IMAP IDLE hält eine TCP-Verbindung offen und der Server sendet
/// proaktiv Benachrichtigungen bei neuen Nachrichten (RFC 2177).
actor IMAPIdleManager {

    private var activeSessions: [UUID: Task<Void, Never>] = [:]
    private let imapService: IMAPService
    private let onNewMessages: ([MailMessage]) -> Void

    init(imapService: IMAPService, onNewMessages: @escaping ([MailMessage]) -> Void) {
        self.imapService   = imapService
        self.onNewMessages = onNewMessages
    }

    // MARK: - Starten

    func startIDLE(for account: MailAccount) {
        guard activeSessions[account.id] == nil else { return }

        let task = Task {
            do {
                try await imapService.startIDLE(account: account)
            } catch {
                // IDLE-Fehler: Nach 30s erneut versuchen
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await startIDLE(for: account)
            }
        }
        activeSessions[account.id] = task
    }

    // MARK: - Stoppen

    func stopIDLE(for accountId: UUID) {
        activeSessions[accountId]?.cancel()
        activeSessions.removeValue(forKey: accountId)
    }

    func stopAll() {
        activeSessions.values.forEach { $0.cancel() }
        activeSessions.removeAll()
    }
}
