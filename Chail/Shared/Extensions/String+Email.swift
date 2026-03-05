import Foundation

extension String {

    /// Prüft ob der String eine valide E-Mail-Adresse ist (einfache Regex).
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Extrahiert die Domain aus einer E-Mail-Adresse.
    var emailDomain: String? {
        let parts = components(separatedBy: "@")
        guard parts.count == 2 else { return nil }
        return parts[1]
    }

    /// Versucht häufig verwendete IMAP/SMTP-Server für bekannte Domains zu erraten.
    var suggestedIMAPHost: String? {
        switch emailDomain?.lowercased() {
        case "gmail.com", "googlemail.com": return "imap.gmail.com"
        case "icloud.com", "me.com", "mac.com": return "imap.mail.me.com"
        case "outlook.com", "hotmail.com", "live.com": return "outlook.office365.com"
        case "yahoo.com", "yahoo.de": return "imap.mail.yahoo.com"
        case "gmx.de", "gmx.net", "gmx.at": return "imap.gmx.net"
        case "web.de": return "imap.web.de"
        case "t-online.de": return "secureimap.t-online.de"
        default: return nil
        }
    }

    var suggestedSMTPHost: String? {
        switch emailDomain?.lowercased() {
        case "gmail.com", "googlemail.com": return "smtp.gmail.com"
        case "icloud.com", "me.com", "mac.com": return "smtp.mail.me.com"
        case "outlook.com", "hotmail.com", "live.com": return "smtp.office365.com"
        case "yahoo.com", "yahoo.de": return "smtp.mail.yahoo.com"
        case "gmx.de", "gmx.net", "gmx.at": return "mail.gmx.net"
        case "web.de": return "smtp.web.de"
        case "t-online.de": return "securesmtp.t-online.de"
        default: return nil
        }
    }
}
