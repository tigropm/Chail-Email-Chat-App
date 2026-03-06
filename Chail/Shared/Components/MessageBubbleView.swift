import SwiftUI

/// Chat-Blase für eine einzelne E-Mail.
struct MessageBubbleView: View {

    let message: MailMessage
    @State private var showFullMessage = false

    private var isOutgoing: Bool { message.isSent }
    private var bubbleColor: Color { isOutgoing ? .blue : Color(.secondarySystemBackground) }
    private var textColor: Color { isOutgoing ? .white : .primary }
    private var alignment: HorizontalAlignment { isOutgoing ? .trailing : .leading }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: alignment, spacing: 4) {
                // Betreff (falls kein simples Re:)
                if !isReplySubject {
                    Text(message.subject)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isOutgoing ? .white.opacity(0.8) : .secondary)
                }

                // Nachrichtentext
                Text(displayText)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .textSelection(.enabled)

                // Anhänge
                if message.hasAttachments {
                    attachmentsView
                }

                // Zeitstempel
                HStack(spacing: 4) {
                    Text(message.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                    if isOutgoing {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bubbleColor, in: BubbleShape(isOutgoing: isOutgoing))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: isOutgoing ? .trailing : .leading)
            .onTapGesture { showFullMessage.toggle() }

            if !isOutgoing { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        .sheet(isPresented: $showFullMessage) {
            FullMessageView(message: message)
        }
    }

    // MARK: - Helpers

    private var isReplySubject: Bool {
        message.subject.lowercased().hasPrefix("re:") || message.inReplyToId != nil
    }

    private var displayText: String {
        let raw = message.bodyPlain ?? ""
        // Zitierten Text ("> ") abschneiden für die Bubble-Vorschau
        let lines = raw.components(separatedBy: "\n")
            .filter { !$0.hasPrefix(">") }
        return lines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? raw : lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var attachmentsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(message.attachments) { attachment in
                AttachmentChipView(attachment: attachment, isOutgoing: isOutgoing)
            }
        }
    }
}

// MARK: - Bubble-Form

struct BubbleShape: Shape {
    let isOutgoing: Bool
    private let radius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let tailRadius: CGFloat = 6

        if isOutgoing {
            path.move(to: CGPoint(x: tl.x + radius, y: tl.y))
            path.addLine(to: CGPoint(x: tr.x - radius, y: tr.y))
            path.addArc(center: CGPoint(x: tr.x - radius, y: tr.y + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: br.x, y: br.y - tailRadius))
            path.addQuadCurve(to: CGPoint(x: br.x - tailRadius, y: br.y), control: br)
            path.addLine(to: CGPoint(x: bl.x + radius, y: bl.y))
            path.addArc(center: CGPoint(x: bl.x + radius, y: bl.y - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: tl.x, y: tl.y + radius))
            path.addArc(center: CGPoint(x: tl.x + radius, y: tl.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: tl.x + radius, y: tl.y))
            path.addLine(to: CGPoint(x: tr.x - radius, y: tr.y))
            path.addArc(center: CGPoint(x: tr.x - radius, y: tr.y + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: br.x, y: br.y - radius))
            path.addArc(center: CGPoint(x: br.x - radius, y: br.y - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: tl.x + tailRadius, y: bl.y))
            path.addQuadCurve(to: CGPoint(x: tl.x, y: bl.y - tailRadius), control: bl)
            path.addLine(to: CGPoint(x: tl.x, y: tl.y + radius))
            path.addArc(center: CGPoint(x: tl.x + radius, y: tl.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Anhang-Chip

struct AttachmentChipView: View {
    let attachment: MailAttachment
    let isOutgoing: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: attachment.sfSymbolName)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.filename)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(attachment.formattedSize)
                    .font(.caption2)
            }
        }
        .foregroundStyle(isOutgoing ? .white : .primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isOutgoing ? .white.opacity(0.2) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Volltext-Ansicht

struct FullMessageView: View {
    let message: MailMessage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.subject)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Von: \(message.from.bestDisplayName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(message.date.formatted(date: .long, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Divider()

                    // Body
                    Text(message.bodyPlain ?? "(Kein Inhalt)")
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Nachricht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
