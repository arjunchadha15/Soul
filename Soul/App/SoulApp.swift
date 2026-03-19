import SwiftUI

@main
struct SoulApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .task {
                    await authService.initialize()
                }
        }
    }
}
