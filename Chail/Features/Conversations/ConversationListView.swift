import SwiftUI

struct ConversationListView: View {

    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var accountRepo: CDAccountRepository

    @State private var searchText = ""
    @State private var showCompose = false

    private var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return store.conversations }
        let q = searchText.lowercased()
        return store.conversations.filter {
            $0.contact.email.contains(q)
            || ($0.contact.displayName?.lowercased().contains(q) ?? false)
            || $0.preview.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.conversations.isEmpty && !store.isSyncing {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .navigationTitle("Chail")
            .searchable(text: $searchText, prompt: "Suchen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if store.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView(draft: MailDraft(to: [], subject: "", bodyPlain: ""))
            }
            .refreshable {
                await refreshConversations()
            }
        }
    }

    // MARK: - Subviews

    private var conversationList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                NavigationLink(value: conversation) {
                    ConversationRowView(conversation: conversation)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Conversation.self) { conversation in
            ChatDetailView(conversation: conversation)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Keine Nachrichten")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Richte ein IMAP-Konto ein, um loszulegen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func refreshConversations() async {
        let accounts = await accountRepo.accounts
            .values
            .first(where: { _ in true }) ?? []
        store.sync(accounts: accounts)
    }
}

// MARK: - Konversations-Zeile

struct ConversationRowView: View {

    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(contact: conversation.contact, size: 50)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.contact.bestDisplayName)
                        .font(.headline)
                        .fontWeight(conversation.hasUnread ? .bold : .regular)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastActivity, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(conversation.preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fontWeight(conversation.hasUnread ? .medium : .regular)
                    Spacer()
                    if conversation.hasUnread {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                    }
                }
            }
        }
    }
}
