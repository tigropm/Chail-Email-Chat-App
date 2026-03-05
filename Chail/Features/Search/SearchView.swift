import SwiftUI
import Combine

struct SearchView: View {

    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var accountRepo: CDAccountRepository

    @State private var query = ""
    @State private var results: [Conversation] = []

    var body: some View {
        NavigationStack {
            Group {
                if query.isEmpty {
                    searchHintView
                } else if results.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Suche")
            .searchable(text: $query, prompt: "Kontakt, Betreff oder Inhalt")
            .onChange(of: query) { _, newValue in
                performSearch(query: newValue)
            }
        }
    }

    // MARK: - Subviews

    private var searchHintView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Suche in allen Nachrichten")
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Keine Ergebnisse für „\(query)"")
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var resultsList: some View {
        List(results) { conversation in
            NavigationLink(value: conversation) {
                ConversationRowView(conversation: conversation)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Conversation.self) { conv in
            ChatDetailView(conversation: conv)
        }
    }

    // MARK: - Suche

    private func performSearch(query: String) {
        let q = query.lowercased()
        guard !q.isEmpty else {
            results = []
            return
        }
        results = store.conversations.filter {
            $0.contact.email.contains(q)
            || ($0.contact.displayName?.lowercased().contains(q) ?? false)
            || $0.messages.contains {
                $0.subject.lowercased().contains(q)
                || ($0.bodyPlain?.lowercased().contains(q) ?? false)
            }
        }
    }
}
