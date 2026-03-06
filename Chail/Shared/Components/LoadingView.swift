import SwiftUI

/// Generische Ladeansicht mit optionaler Nachricht.
struct LoadingView: View {

    let message: String

    init(_ message: String = "Wird geladen …") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
