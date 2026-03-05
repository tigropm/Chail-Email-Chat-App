# Chail — E-Mail als Chat-App (iOS, nativ Swift)

> **Chail** = **Ch**at + M**ail** — eine native iOS-App, die IMAP-E-Mails als Konversation im Chat-Stil darstellt.

---

## Inhaltsverzeichnis

1. [Produktvision](#1-produktvision)
2. [Kernkonzept: Mail-als-Chat](#2-kernkonzept-mail-als-chat)
3. [Architektur](#3-architektur)
4. [Datenmodell](#4-datenmodell)
5. [IMAP-Integration](#5-imap-integration)
6. [UI/UX-Konzept](#6-uiux-konzept)
7. [Projektstruktur](#7-projektstruktur)
8. [Technologie-Stack](#8-technologie-stack)
9. [Roadmap](#9-roadmap)

---

## 1. Produktvision

Standard-Mail-Apps zeigen E-Mails als Liste von Einzelnachrichten — losgelöst vom Kontext. **Chail** gruppiert alle E-Mails zwischen dir und einem bestimmten Absender/Empfänger in einen **kontinuierlichen Chatverlauf**, wie man es von iMessage oder WhatsApp kennt.

**Kernversprechen:**
- Jede Konversation mit einer Person = ein Chat-Thread
- Antworten erscheinen direkt als Blasen unterhalb der letzten Nachricht
- Suche, Anhänge und Formatierung bleiben vollständig erhalten
- Nur IMAP — kein proprietäres Backend, volle Kontrolle über eigene Daten

---

## 2. Kernkonzept: Mail-als-Chat

### 2.1 Filterlogik: Gruppierung nach Absender

Die zentrale Idee: E-Mails werden **nicht nach Betreff/Thread-ID**, sondern primär nach **E-Mail-Adresse des Gesprächspartners** gruppiert.

```
Posteingang (IMAP)
│
├── von: alice@example.com  ──►  Chat mit Alice
│   ├── [Betreff: Meeting]
│   ├── [Betreff: Re: Meeting]
│   └── [Betreff: Unterlagen]
│
├── von: bob@company.de     ──►  Chat mit Bob
│   ├── [Betreff: Angebot]
│   └── [Betreff: Re: Angebot]
│
└── von: newsletter@shop.de ──►  Chat mit Shop-Newsletter
```

**Normalisierungsregel:**
- Eigene gesendete Mails (Ordner: Sent) + empfangene Mails → gleiche Konversation
- `From:`, `To:`, `CC:` werden ausgewertet, um den "anderen Teilnehmer" zu bestimmen
- Gruppen-Mails (mehrere externe Empfänger) → eigene "Gruppen-Konversation"

### 2.2 Nachrichtenfluss

```
Empfangene Mail  →  Blase LINKS  (grauer Hintergrund)
Gesendete Mail   →  Blase RECHTS (blauer Hintergrund)
```

Zeitstempel werden wie in iMessage nur bei größeren Zeitabständen eingeblendet.

### 2.3 Antworten

Das Eingabefeld unten erstellt eine neue E-Mail mit:
- `To:` = E-Mail-Adresse des Gesprächspartners
- `Subject:` = letzter Betreff (automatisch mit `Re:` Prefix)
- `In-Reply-To:` / `References:` = korrekte Mail-Header für Thread-Kompatibilität

---

## 3. Architektur

### 3.1 Schichtenmodell (Clean Architecture)

```
┌─────────────────────────────────────────────┐
│              Presentation Layer             │
│   SwiftUI Views + ViewModels (MVVM)         │
├─────────────────────────────────────────────┤
│               Domain Layer                  │
│   UseCases · Entities · Repository-Proto.   │
├─────────────────────────────────────────────┤
│             Infrastructure Layer            │
│   IMAPService · SMTPService · LocalCache    │
│   (SwiftNIO + MailCore2 / eigener IMAP)     │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│   CoreData (lokale Persistenz) · Keychain   │
└─────────────────────────────────────────────┘
```

### 3.2 MVVM + Combine / async-await

- **Models**: Swift-Structs (Codable, Sendable)
- **ViewModels**: `@Observable` oder `ObservableObject` + Combine
- **Views**: SwiftUI, keine UIKit-Wrapper außer für komplexe Custom-Controls
- **Nebenläufigkeit**: Swift Concurrency (`async/await`, `Actor`)

---

## 4. Datenmodell

### 4.1 Kern-Entities

```swift
// Repräsentiert ein IMAP-Konto
struct MailAccount: Identifiable, Codable {
    let id: UUID
    var displayName: String
    var emailAddress: String
    var imapHost: String
    var imapPort: Int          // Standard: 993 (TLS)
    var smtpHost: String
    var smtpPort: Int          // Standard: 587 (STARTTLS) / 465 (TLS)
    var username: String
    // Passwort wird im Keychain gespeichert — NICHT im Modell
    var useSSL: Bool
    var lastSyncDate: Date?
}

// Eine einzelne E-Mail (normalisiert aus IMAP-Rohdaten)
struct MailMessage: Identifiable, Sendable {
    let id: String             // Message-ID Header
    let uid: UInt32            // IMAP UID
    let accountId: UUID
    let folderName: String
    var from: ContactAddress
    var to: [ContactAddress]
    var cc: [ContactAddress]
    var subject: String
    var bodyPlain: String?
    var bodyHTML: String?
    var attachments: [MailAttachment]
    var date: Date
    var isRead: Bool
    var isSent: Bool           // aus Sent-Ordner
    var inReplyToId: String?
    var references: [String]
}

// Gesprächspartner (normalisiert)
struct ContactAddress: Hashable, Codable {
    var displayName: String?
    var email: String           // lowercase, trimmed
}

// Konversation = alle Mails mit einem Kontakt
struct Conversation: Identifiable {
    let id: String              // = normalisierte E-Mail-Adresse des Kontakts
    var contact: ContactAddress
    var messages: [MailMessage] // chronologisch sortiert
    var lastMessage: MailMessage?
    var unreadCount: Int
    var accountId: UUID
}

struct MailAttachment: Identifiable {
    let id: UUID
    let filename: String
    let mimeType: String
    let size: Int
    var localURL: URL?          // nach Download
}
```

### 4.2 Persistenz (CoreData)

```
CDAccount          ←→  MailAccount
CDMessage          ←→  MailMessage
CDAttachment       ←→  MailAttachment
CDConversation     ←→  Conversation (denormalisiert für Performance)
```

Anhänge werden lazy geladen und im `FileManager` (App-Container) gecacht.

---

## 5. IMAP-Integration

### 5.1 Bibliothek: MailCore2 / eigenes SwiftNIO-IMAP

**Option A: MailCore2** (Objective-C, stabile Basis, CocoaPods/SPM-Wrapper)
- Pro: Sehr ausgereift, unterstützt IDLE, OAUTH2, S/MIME
- Con: Objective-C-Bridge, keine native Swift Concurrency

**Option B: swift-nio-imap** (Apple/SwiftNIO, rein Swift)
- Pro: Native Swift, async/await nativ
- Con: Geringerer Reifegrad, weniger Features out-of-the-box

**Empfehlung Phase 1:** MailCore2 via SPM-Wrapper für Stabilität.

### 5.2 IMAP-Ablauf

```
1. CONNECT        tcp+tls → imapHost:993
2. AUTHENTICATE   LOGIN / PLAIN / XOAUTH2
3. SELECT         INBOX
4. FETCH          UID FETCH 1:* (FLAGS ENVELOPE)   → Metadaten
5. FETCH          UID FETCH <uid> BODY[]            → Volltext (lazy)
6. IDLE           IMAP IDLE für Push-Benachrichtigungen
7. APPEND         Gesendete Mails in Sent-Ordner kopieren
```

### 5.3 Sync-Strategie

```
App-Start
  └─► Quick Sync: Neue UIDs seit letztem Sync holen (SEARCH UID uid_next:*)
      └─► Background Sync: Ältere Nachrichten paginiert laden
          └─► IDLE: Auf neue Nachrichten warten (Background Task)
```

### 5.4 Sicherheit

| Aspekt | Umsetzung |
|---|---|
| Passwörter | iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) |
| TLS/SSL | Systemstack (SecureTransport / Network.framework) |
| Zertifikatsvalidierung | Standard iOS — kein SSL-Pinning bypass |
| App-Sperre | Face ID / Touch ID via LocalAuthentication |

---

## 6. UI/UX-Konzept

### 6.1 App-Struktur (Navigation)

```
TabBar
├── 💬 Chats            ← Konversationsliste
│   └── ChatDetailView  ← Chatverlauf mit einer Person
├── 📁 Ordner           ← Klassische IMAP-Ordner (optional)
├── 🔍 Suche            ← Volltext-Suche über alle Mails
└── ⚙️ Einstellungen    ← Konten, Erscheinungsbild, Benachrichtigungen
```

### 6.2 Screens im Detail

#### ConversationListView (Chat-Liste)
```
┌────────────────────────────────┐
│  ≡  Chail            🖊  +     │
│──────────────────────────────  │
│ [Avatar] Alice M.        14:32 │
│  Hey, das Dokument ist fer...  │
│──────────────────────────────  │
│ [Avatar] Bob K.          Di.   │
│  • Angebot angehängt          │  ← Ungelesen = fett + blauer Punkt
│──────────────────────────────  │
│ [Avatar] Newsletter      Mo.   │
│  Dein wöchentlicher Digest... │
└────────────────────────────────┘
```

#### ChatDetailView (Chatverlauf)
```
┌────────────────────────────────┐
│ ← [Avatar] Alice Müller  ···   │
│────────────────────────────────│
│                   Montag       │
│ ╭─────────────────────────╮    │
│ │ Kannst du mir das       │    │
│ │ Protokoll schicken?     │    │
│ ╰─────────────────────────╯    │
│ 10:14                          │
│                                │
│         ╭─────────────────╮    │
│         │ Klar, ist im    │    │
│         │ Anhang!    📎   │    │
│         ╰─────────────────╯    │
│                   10:22 ✓✓     │
│ ╭─────────────────────────╮    │
│ │ Danke! Schaue ich mir   │    │
│ │ gleich an.              │    │
│ ╰─────────────────────────╯    │
│────────────────────────────────│
│ [📎] [Aa]  Nachricht...  [▶]  │
└────────────────────────────────┘
```

#### Compose / Antwort
- Inline am unteren Rand für einfache Textnachrichten
- Vollbild-Compose für neue Konversationen / komplexe Mails
- HTML-Body wird immer generiert (Plain-Text als Fallback mitgeschickt)

### 6.3 Design-Prinzipien

- **iOS Human Interface Guidelines** — native Look & Feel
- **Dynamic Type** — vollständig skalierbare Schriften
- **Dark Mode** — native Color Assets
- **Accessibility** — VoiceOver-Labels auf allen Chat-Elementen
- **Haptic Feedback** — beim Senden (UIImpactFeedbackGenerator)

---

## 7. Projektstruktur

```
Chail/
├── App/
│   ├── ChailApp.swift              ← @main Entry Point
│   └── AppDependencies.swift       ← DI-Container (Environment)
│
├── Features/
│   ├── Conversations/
│   │   ├── ConversationListView.swift
│   │   ├── ConversationListViewModel.swift
│   │   ├── ChatDetailView.swift
│   │   └── ChatDetailViewModel.swift
│   │
│   ├── Compose/
│   │   ├── ComposeView.swift
│   │   └── ComposeViewModel.swift
│   │
│   ├── Accounts/
│   │   ├── AccountSetupView.swift
│   │   ├── AccountSetupViewModel.swift
│   │   └── IMAPValidator.swift
│   │
│   ├── Search/
│   │   ├── SearchView.swift
│   │   └── SearchViewModel.swift
│   │
│   └── Settings/
│       └── SettingsView.swift
│
├── Domain/
│   ├── Entities/
│   │   ├── MailAccount.swift
│   │   ├── MailMessage.swift
│   │   ├── Conversation.swift
│   │   ├── ContactAddress.swift
│   │   └── MailAttachment.swift
│   │
│   ├── UseCases/
│   │   ├── SyncMailsUseCase.swift
│   │   ├── SendMailUseCase.swift
│   │   ├── BuildConversationsUseCase.swift
│   │   └── SearchMailsUseCase.swift
│   │
│   └── Repositories/
│       ├── MailRepositoryProtocol.swift
│       └── AccountRepositoryProtocol.swift
│
├── Infrastructure/
│   ├── IMAP/
│   │   ├── IMAPService.swift           ← Verbindung & FETCH
│   │   ├── IMAPIdleManager.swift       ← IDLE Push-Benachrichtigungen
│   │   └── IMAPMessageMapper.swift     ← Rohdaten → Domain Entity
│   │
│   ├── SMTP/
│   │   └── SMTPService.swift           ← Mails senden
│   │
│   ├── Persistence/
│   │   ├── CoreDataStack.swift
│   │   ├── CDMailRepository.swift
│   │   └── CDAccountRepository.swift
│   │
│   └── Keychain/
│       └── KeychainService.swift
│
├── Shared/
│   ├── Extensions/
│   │   ├── String+Email.swift
│   │   ├── Date+Formatting.swift
│   │   └── View+Conditional.swift
│   │
│   └── Components/
│       ├── AvatarView.swift
│       ├── MessageBubbleView.swift
│       ├── AttachmentPreviewView.swift
│       └── LoadingView.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings (DE, EN)
    └── Chail.xcdatamodeld
```

---

## 8. Technologie-Stack

| Bereich | Technologie | Begründung |
|---|---|---|
| Sprache | Swift 5.10+ | Nativ, modern, typsicher |
| UI | SwiftUI 5 | Deklarativ, iOS 17+ Features |
| Nebenläufigkeit | Swift Concurrency | `async/await`, Actors |
| Reaktivität | Combine / `@Observable` | State-Management |
| IMAP | MailCore2 (SPM) | Ausgereift, IDLE-Support |
| SMTP | MailCore2 | Einheitliche Bibliothek |
| Persistenz | CoreData | Offline-First, iCloud-sync möglich |
| Keychain | Security.framework | Passwörter sicher speichern |
| Biometrie | LocalAuthentication | Face ID / Touch ID |
| Benachrichtigung | UserNotifications | Push bei IDLE-Event |
| Min. iOS | iOS 17.0 | SwiftUI 5, `@Observable` |
| Paketmanager | Swift Package Manager | Kein CocoaPods/Carthage |

---

## 9. Roadmap

### Phase 1 — MVP (Einzelkonto, IMAP-Lesen)
- [ ] IMAP-Verbindung & Authentifizierung (Login/Plain)
- [ ] Nachrichten-Sync (Metadaten + Body lazy)
- [ ] Konversationsgruppierung nach Absender
- [ ] ChatDetailView (read-only)
- [ ] Antworten senden (SMTP)
- [ ] CoreData-Persistenz
- [ ] Konto-Setup-Flow

### Phase 2 — Erweiterte Features
- [ ] Mehrere IMAP-Konten
- [ ] IMAP IDLE (Echtzeit-Push)
- [ ] Anhänge herunterladen & vorschauen
- [ ] Volltext-Suche (CoreSpotlight)
- [ ] Gruppen-Konversationen
- [ ] Swipe-to-Delete / Archivieren

### Phase 3 — Polish & Power-Features
- [ ] OAUTH2 (Gmail, Outlook)
- [ ] HTML-Mail-Rendering (WKWebView)
- [ ] Signatur-Editor
- [ ] Face ID App-Sperre
- [ ] iCloud Backup der Konten (ohne Passwörter)
- [ ] iPad / macOS (Catalyst) Support
- [ ] Widgets (letzte Konversation)

---

## Lizenz

MIT — siehe [LICENSE](LICENSE)
