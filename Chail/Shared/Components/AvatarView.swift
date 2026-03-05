import SwiftUI

/// Zeigt einen Avatar mit Initialen oder Kontaktbild.
struct AvatarView: View {

    let contact: ContactAddress
    let size: CGFloat

    private var backgroundColor: Color {
        // Deterministisch aus dem E-Mail-Hash
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo, .red]
        let index = abs(contact.email.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.gradient)
            Text(contact.initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        AvatarView(contact: ContactAddress(displayName: "Alice Müller", email: "alice@example.com"), size: 44)
        AvatarView(contact: ContactAddress(displayName: "Bob", email: "bob@company.de"), size: 44)
        AvatarView(contact: ContactAddress(email: "newsletter@shop.de"), size: 44)
    }
    .padding()
}
