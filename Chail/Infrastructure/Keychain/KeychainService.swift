import Foundation
import Security

/// Einfacher Wrapper um die iOS Keychain.
/// Passwörter werden mit kSecAttrAccessibleWhenUnlockedThisDeviceOnly gespeichert.
final class KeychainService {

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed

        var errorDescription: String? {
            switch self {
            case .saveFailed(let s):   return "Keychain-Speicherfehler (OSStatus \(s))"
            case .loadFailed(let s):   return "Keychain-Ladefehler (OSStatus \(s))"
            case .deleteFailed(let s): return "Keychain-Löschfehler (OSStatus \(s))"
            case .dataConversionFailed: return "Datenkonvertierung fehlgeschlagen"
            }
        }
    }

    // MARK: - Speichern

    func save(password: String, for key: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        // Erst löschen falls vorhanden
        try? delete(key: key)

        let query: [CFString: Any] = [
            kSecClass:                kSecClassGenericPassword,
            kSecAttrAccount:          key,
            kSecAttrService:          "de.chail.app",
            kSecValueData:            data,
            kSecAttrAccessible:       kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - Laden

    func load(key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecAttrService:      "de.chail.app",
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.loadFailed(status)
        }
        return password
    }

    // MARK: - Löschen

    func delete(key: String) throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: "de.chail.app"
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
