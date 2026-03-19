import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private init() {}

    func initialize() async {
        await refreshSession()
    }

    func refreshSession() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            await fetchCurrentUser(id: session.user.id)
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
        isLoading = false
    }

    func signUp(email: String, password: String, username: String, fullName: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        let userId = response.user.id

        let newUser = AppUser(
            id: userId,
            username: username,
            fullName: fullName,
            avatarUrl: nil,
            bio: nil,
            createdAt: Date()
        )

        try await supabase
            .from("users")
            .insert(newUser)
            .execute()

        isAuthenticated = true
        currentUser = newUser
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        isAuthenticated = true
        await fetchCurrentUser(id: session.user.id)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }

    private func fetchCurrentUser(id: UUID) async {
        do {
            let user: AppUser = try await supabase
                .from("users")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            currentUser = user
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func updateProfile(fullName: String, bio: String?) async throws {
        guard let userId = currentUser?.id else { return }

        struct ProfileUpdate: Encodable {
            let fullName: String
            let bio: String?
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case bio
            }
        }

        try await supabase
            .from("users")
            .update(ProfileUpdate(fullName: fullName, bio: bio))
            .eq("id", value: userId.uuidString)
            .execute()

        currentUser?.fullName = fullName
        currentUser?.bio = bio
    }
}

enum AuthError: LocalizedError {
    case noUser
    case usernameUnavailable

    var errorDescription: String? {
        switch self {
        case .noUser: return "No user was returned after sign up."
        case .usernameUnavailable: return "That username is already taken."
        }
    }
}
