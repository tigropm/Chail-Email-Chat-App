import SwiftUI

struct ComposeView: View {

    @State var draft: MailDraft
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountRepo: CDAccountRepository
    @Environment(\.mailService) private var mailService

    @State private var isSending = false
    @State private var sendError: Error?
    @State private var selectedAccount: MailAccount?

    private var canSend: Bool {
        !draft.to.isEmpty &&
        !draft.bodyPlain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("An") {
                    recipientField
                }

                Section("Betreff") {
                    TextField("Betreff", text: $draft.subject)
                }

                Section("Nachricht") {
                    TextEditor(text: $draft.bodyPlain)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Neue Mail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Senden") { send() }
                            .fontWeight(.semibold)
                            .disabled(!canSend)
                    }
                }
            }
            .alert("Fehler beim Senden", isPresented: .constant(sendError != nil)) {
                Button("OK") { sendError = nil }
            } message: {
                Text(sendError?.localizedDescription ?? "")
            }
        }
    }

    // MARK: - Empfänger-Feld

    private var recipientField: some View {
        HStack {
            if draft.to.isEmpty {
                Text("An:")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.to, id: \.email) { addr in
                    Text(addr.bestDisplayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(.blue.opacity(0.4)))
                }
            }
        }
    }

    // MARK: - Senden

    private func send() {
        guard let account = selectedAccount else { return }
        isSending = true
        Task {
            defer { isSending = false }
            do {
                let useCase = SendMailUseCase(
                    smtpService:    SMTPService(keychain: KeychainService()),
                    mailRepository: CDMailRepository(stack: .shared)
                )
                try await useCase.execute(draft: draft, account: account)
                dismiss()
            } catch {
                sendError = error
            }
        }
    }
}
