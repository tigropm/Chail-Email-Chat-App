import Foundation

struct MailAttachment: Identifiable, Hashable, Sendable {

    let id: UUID
    let messageId: String
    let filename: String
    let mimeType: String
    let size: Int           // Bytes
    /// Lokaler Pfad nach dem Download (optional)
    var localURL: URL?

    var isDownloaded: Bool { localURL != nil }

    /// Menschenlesbare Dateigröße (z.B. "2,4 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    /// SF Symbol-Name passend zum MIME-Typ
    var sfSymbolName: String {
        switch mimeType {
        case let m where m.hasPrefix("image/"):   return "photo"
        case let m where m.hasPrefix("video/"):   return "film"
        case let m where m.hasPrefix("audio/"):   return "waveform"
        case "application/pdf":                   return "doc.richtext"
        case let m where m.contains("zip") || m.contains("archive"): return "archivebox"
        default:                                  return "doc"
        }
    }
}
