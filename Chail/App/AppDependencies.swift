import SwiftUI
import Combine

/// Zentraler Dependency-Container der App.
/// Wird als EnvironmentObject in der View-Hierarchie bereitgestellt.
final class AppDependencies: ObservableObject {

    // MARK: - Infrastructure

    let keychainService: KeychainService
    let coreDataStack: CoreDataStack

    // MARK: - Repositories

    let accountRepository: CDAccountRepository
    let mailRepository: CDMailRepository

    // MARK: - Services

    let mailService: IMAPService

    // MARK: - Stores / ViewModels auf App-Ebene

    let conversationStore: ConversationStore

    // MARK: - Init

    init() {
        keychainService  = KeychainService()
        coreDataStack    = CoreDataStack.shared
        accountRepository = CDAccountRepository(stack: coreDataStack)
        mailRepository   = CDMailRepository(stack: coreDataStack)
        mailService      = IMAPService(
            keychain: keychainService,
            mailRepository: mailRepository
        )
        conversationStore = ConversationStore(
            mailRepository: mailRepository,
            mailService: mailService
        )
    }
}

// MARK: - EnvironmentKey für IMAPService

private struct MailServiceKey: EnvironmentKey {
    static let defaultValue: IMAPService = IMAPService(
        keychain: KeychainService(),
        mailRepository: CDMailRepository(stack: .shared)
    )
}

extension EnvironmentValues {
    var mailService: IMAPService {
        get { self[MailServiceKey.self] }
        set { self[MailServiceKey.self] = newValue }
    }
}
