import SwiftUI
import Combine

/// Root-View der App. Zeigt entweder den Konto-Setup-Bildschirm
/// oder die Haupt-Tab-Navigation.
struct RootView: View {

    @EnvironmentObject private var accountRepo: CDAccountRepository
    @State private var accounts: [MailAccount] = []
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if accounts.isEmpty {
                onboardingView
            } else {
                mainTabView
            }
        }
        .onReceive(accountRepo.accounts) { loaded in
            accounts = loaded
            showOnboarding = loaded.isEmpty
        }
    }

    // MARK: - Onboarding

    private var onboardingView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                Text("Willkommen bei Chail")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Deine E-Mails als Chat.\nSimple, privat, nativ.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button {
                showOnboarding = true
            } label: {
                Text("IMAP-Konto einrichten")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showOnboarding) {
            AccountSetupView()
        }
    }

    // MARK: - Haupt-Navigation

    private var mainTabView: some View {
        TabView {
            ConversationListView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SearchView()
                .tabItem {
                    Label("Suche", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
        }
    }
}
