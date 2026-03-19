import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundStyle(Color.soulTextPrimary)

                        Text("Start documenting your journey.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soulTextSecondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 12) {
                        SoulTextField(
                            placeholder: "Full Name",
                            text: $fullName,
                            autocapitalization: .words
                        )

                        SoulTextField(
                            placeholder: "Username",
                            text: $username,
                            autocapitalization: .never
                        )

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
                        title: "Create Account",
                        action: signUp,
                        isLoading: isLoading,
                        isDisabled: !isFormValid
                    )

                    Button("Already have an account? Sign in") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.soulTextSecondary)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var isFormValid: Bool {
        !email.isBlank && !password.isBlank &&
        !username.isBlank && !fullName.isBlank &&
        password.count >= 6
    }

    private func signUp() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    username: username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
