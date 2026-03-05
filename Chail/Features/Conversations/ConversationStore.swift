import Foundation
import Combine

/// Zentraler Store für alle Konversationen.
/// Wird als ObservableObject in der gesamten App geteilt.
@MainActor
final class ConversationStore: ObservableObject {

    @Published var conversations: [Conversation] = []
    @Published var isSyncing: Bool = false
    @Published var syncError: Error?

    private let mailRepository: any MailRepositoryProtocol
    private let mailService: IMAPService
    private var cancellables = Set<AnyCancellable>()

    init(mailRepository: any MailRepositoryProtocol, mailService: IMAPService) {
        self.mailRepository = mailRepository
        self.mailService    = mailService
    }

    // MARK: - Sync

    func sync(accounts: [MailAccount]) {
        guard !isSyncing else { return }
        isSyncing  = true
        syncError  = nil

        Task {
            defer { self.isSyncing = false }
            do {
                for account in accounts {
                    let useCase = SyncMailsUseCase(
                        imapService:    mailService,
                        mailRepository: mailRepository
                    )
                    try await useCase.execute(account: account)
                }
            } catch {
                syncError = error
            }
        }
    }

    // MARK: - Beobachten

    func observe(accountId: UUID, account: MailAccount) {
        mailRepository.conversations(for: accountId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loaded in
                guard let self else { return }
                // Existierende Konversationen anderer Accounts beibehalten
                let other = self.conversations.filter { $0.accountId != accountId }
                self.conversations = (other + loaded).sorted()
            }
            .store(in: &cancellables)
    }
}
