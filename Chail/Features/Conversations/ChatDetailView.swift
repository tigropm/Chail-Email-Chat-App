import SwiftUI

struct ChatDetailView: View {

    let conversation: Conversation

    @State private var replyText: String = ""
    @State private var showCompose = false
    @State private var isReplying = false
    @FocusState private var inputFocused: Bool

    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var accountRepo: CDAccountRepository

    var body: some View {
        VStack(spacing: 0) {
            messageScrollView
            Divider()
            replyBar
        }
        .navigationTitle(conversation.contact.bestDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                AvatarView(contact: conversation.contact, size: 32)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Neue Mail an \(conversation.contact.bestDisplayName)") {
                        showCompose = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeView(draft: MailDraft(
                to:      [conversation.contact],
                subject: "",
                bodyPlain: ""
            ))
        }
    }

    // MARK: - Nachrichtenliste

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { idx, message in
                        VStack(spacing: 4) {
                            // Zeitstempel wenn Abstand > 1 Stunde
                            if shouldShowTimestamp(at: idx) {
                                TimestampView(date: message.date)
                                    .padding(.vertical, 8)
                            }
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onAppear {
                if let last = conversation.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Antwort-Leiste

    private var replyBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Nachricht …", text: $replyText, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: Capsule())
                .lineLimit(1...6)
                .focused($inputFocused)

            Button {
                sendReply()
            } label: {
                Image(systemName: replyText.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(replyText.isEmpty ? .secondary : .blue)
            }
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isReplying)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Helpers

    private func shouldShowTimestamp(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let prev = conversation.messages[index - 1]
        let curr = conversation.messages[index]
        return curr.date.timeIntervalSince(prev.date) > 3600
    }

    private func sendReply() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isReplying = true
        replyText  = ""

        Task {
            defer { isReplying = false }
            // TODO: SendMailUseCase aufrufen
            // Optimistic UI: Nachricht sofort lokal anzeigen
        }
    }
}

// MARK: - Zeitstempel-Trennlinie

struct TimestampView: View {
    let date: Date

    var body: some View {
        Text(date.chatTimestamp)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private extension Date {
    var chatTimestamp: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) {
            return formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInYesterday(self) {
            return "Gestern \(formatted(date: .omitted, time: .shortened))"
        } else if cal.isDate(self, equalTo: .now, toGranularity: .weekOfYear) {
            return formatted(.dateTime.weekday(.wide).hour().minute())
        } else {
            return formatted(date: .abbreviated, time: .shortened)
        }
    }
}
