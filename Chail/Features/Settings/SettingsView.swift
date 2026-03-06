import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var accountRepo: CDAccountRepository
    @State private var showAddAccount = false
    @State private var accounts: [MailAccount] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Konten") {
                    ForEach(accounts) { account in
                        AccountRowView(account: account)
                    }
                    .onDelete { indexSet in
                        deleteAccounts(at: indexSet)
                    }

                    Button {
                        showAddAccount = true
                    } label: {
                        Label("Konto hinzufügen", systemImage: "plus.circle.fill")
                    }
                }

                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .sheet(isPresented: $showAddAccount) {
                AccountSetupView()
            }
            .onReceive(accountRepo.accounts) { loaded in
                accounts = loaded
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private func deleteAccounts(at indexSet: IndexSet) {
        let toDelete = indexSet.map { accounts[$0] }
        Task {
            for account in toDelete {
                try? await accountRepo.delete(accountId: account.id)
                try? KeychainService().delete(key: account.keychainKey)
            }
        }
    }
}

// MARK: - Konto-Zeile

struct AccountRowView: View {
    let account: MailAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(account.displayName)
                .font(.headline)
            Text(account.emailAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let sync = account.lastSyncDate {
                Text("Zuletzt synchronisiert: \(sync, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
