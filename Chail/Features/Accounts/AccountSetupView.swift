import SwiftUI

struct AccountSetupView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountRepo: CDAccountRepository
    @Environment(\.mailService) private var mailService

    @State private var displayName = ""
    @State private var emailAddress = ""
    @State private var password = ""
    @State private var imapHost = ""
    @State private var imapPort = "993"
    @State private var smtpHost = ""
    @State private var smtpPort = "587"
    @State private var imapUseSSL = true
    @State private var smtpUseSSL = false
    @State private var showAdvanced = false

    @State private var isValidating = false
    @State private var validationError: String?
    @State private var validationSuccess = false

    private var isFormValid: Bool {
        !displayName.isEmpty && emailAddress.contains("@") &&
        !password.isEmpty && !imapHost.isEmpty && !smtpHost.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deine Daten") {
                    TextField("Name (Anzeigename)", text: $displayName)
                        .textContentType(.name)
                    TextField("E-Mail-Adresse", text: $emailAddress)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Passwort", text: $password)
                        .textContentType(.password)
                }

                Section("IMAP (Empfang)") {
                    TextField("Server (z.B. imap.gmail.com)", text: $imapHost)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("993", text: $imapPort)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    Toggle("SSL/TLS", isOn: $imapUseSSL)
                }

                Section("SMTP (Versand)") {
                    TextField("Server (z.B. smtp.gmail.com)", text: $smtpHost)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("587", text: $smtpPort)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    Toggle("SSL/TLS", isOn: $smtpUseSSL)
                }

                if let error = validationError {
                    Section {
                        Label(error, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if validationSuccess {
                    Section {
                        Label("Verbindung erfolgreich", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button {
                        validateAndSave()
                    } label: {
                        HStack {
                            Spacer()
                            if isValidating {
                                ProgressView()
                            } else {
                                Text("Konto hinzufügen")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isValidating)
                }
            }
            .navigationTitle("Konto hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    // MARK: - Validierung & Speichern

    private func validateAndSave() {
        guard let imapPortInt = Int(imapPort),
              let smtpPortInt = Int(smtpPort) else {
            validationError = "Ungültige Portnummern"
            return
        }

        isValidating   = true
        validationError = nil
        validationSuccess = false

        let account = MailAccount(
            displayName:  displayName,
            emailAddress: emailAddress,
            imapHost:     imapHost,
            imapPort:     imapPortInt,
            imapUseSSL:   imapUseSSL,
            smtpHost:     smtpHost,
            smtpPort:     smtpPortInt,
            smtpUseSSL:   smtpUseSSL,
            username:     emailAddress
        )

        Task {
            defer { isValidating = false }
            do {
                // Passwort im Keychain speichern
                try KeychainService().save(password: password, for: account.keychainKey)

                // Verbindung testen
                try await mailService.validateConnection(account: account)
                validationSuccess = true

                // Konto persistieren
                try await accountRepo.save(account: account)

                // Kurze Wartezeit damit der Nutzer den Erfolg sieht
                try await Task.sleep(nanoseconds: 500_000_000)
                dismiss()
            } catch {
                validationError = error.localizedDescription
                try? KeychainService().delete(key: account.keychainKey)
            }
        }
    }
}
