import Foundation

/// Synchronisiert neue E-Mails vom IMAP-Server für ein Konto.
actor SyncMailsUseCase {

    private let imapService: IMAPService
    private let mailRepository: any MailRepositoryProtocol

    init(imapService: IMAPService, mailRepository: any MailRepositoryProtocol) {
        self.imapService    = imapService
        self.mailRepository = mailRepository
    }

    /// Holt neue Nachrichten seit dem letzten Sync.
    /// - Returns: Anzahl neu geladener Nachrichten
    @discardableResult
    func execute(account: MailAccount, folder: String = "INBOX") async throws -> Int {
        let highestUID = await mailRepository.highestUID(in: folder, accountId: account.id)
        let messages   = try await imapService.fetchMessages(
            account:    account,
            folder:     folder,
            sinceUID:   highestUID + 1
        )

        guard !messages.isEmpty else { return 0 }
        try await mailRepository.save(messages: messages)
        return messages.count
    }
}
