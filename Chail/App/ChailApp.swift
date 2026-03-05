import SwiftUI

@main
struct ChailApp: App {

    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies.accountRepository)
                .environmentObject(dependencies.conversationStore)
                .environment(\.mailService, dependencies.mailService)
        }
    }
}
