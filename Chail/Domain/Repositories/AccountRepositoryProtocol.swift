import Foundation
import Combine

protocol AccountRepositoryProtocol: AnyObject {

    var accounts: AnyPublisher<[MailAccount], Never> { get }

    func save(account: MailAccount) async throws
    func delete(accountId: UUID) async throws
    func account(id: UUID) async throws -> MailAccount?
    func updateSyncDate(_ date: Date, for accountId: UUID) async throws
}
