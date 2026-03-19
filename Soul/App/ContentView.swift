import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {
                splashView
            } else if authService.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var splashView: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()
            Text("Soul")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(Color.soulTextPrimary)
                .tracking(-2)
        }
    }
}
