import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundStyle(Color.soulTextPrimary)

                    Text("Continue your journey.")
                        .font(.subheadline)
                        .foregroundStyle(Color.soulTextSecondary)
                }

                VStack(spacing: 12) {
                    SoulTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    SoulTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true
                    )
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                SoulButton(
                    title: "Sign In",
                    isLoading: isLoading,
                    isDisabled: email.isBlank || password.isBlank,
                    action: signIn
                )

                Spacer()

                Button("Don't have an account? Get started") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(Color.soulTextSecondary)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
