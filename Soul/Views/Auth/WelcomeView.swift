import SwiftUI

struct WelcomeView: View {
    @State private var showAuth = false
    @State private var isLogin = false

    var body: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline
                VStack(spacing: 20) {
                    Text("Soul")
                        .font(.system(size: 64, weight: .black, design: .default))
                        .foregroundStyle(Color.soulTextPrimary)
                        .tracking(-2)

                    Text("Document your journey.\nNot your highlight reel.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.soulTextSecondary)
                        .lineSpacing(4)
                }

                Spacer()
                Spacer()

                // CTA buttons
                VStack(spacing: 12) {
                    SoulButton(title: "Get Started") {
                        isLogin = false
                        showAuth = true
                    }

                    SoulButton(title: "Sign In", style: .secondary) {
                        isLogin = true
                        showAuth = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showAuth) {
            if isLogin {
                LoginView()
            } else {
                SignUpView()
            }
        }
    }
}

#Preview {
    WelcomeView()
}
