import Foundation

/// Eine normalisierte E-Mail-Adresse mit optionalem Anzeigenamen.
struct ContactAddress: Hashable, Equatable, Codable, Sendable {

    var displayName: String?
    /// Immer lowercase + getrimmt
    var email: String

    init(displayName: String? = nil, email: String) {
        self.displayName = displayName?.trimmingCharacters(in: .whitespaces)
        self.email       = email.lowercased().trimmingCharacters(in: .whitespaces)
    }

    /// Der zur Anzeige beste Name: Anzeigename falls vorhanden, sonst E-Mail
    var bestDisplayName: String {
        if let name = displayName, !name.isEmpty { return name }
        return email
    }

    /// Initialen für Avatar (max. 2 Zeichen)
    var initials: String {
        let source = bestDisplayName
        let parts  = source.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(source.prefix(2)).uppercased()
    }
}
