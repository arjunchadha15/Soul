import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authService: AuthService
    let userId: UUID

    @State private var user: AppUser?
    @State private var projects: [Project] = []
    @State private var isLoading = true
    @State private var friendshipStatus: FriendshipButtonState = .none
    @State private var friendshipId: UUID?

    enum FriendshipButtonState {
        case none, pending, friends
    }

    var body: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Color.soulAccent)
            } else if let user {
                ScrollView {
                    VStack(spacing: 0) {
                        profileHeader(user: user)

                        if authService.currentUser?.id != userId {
                            friendshipButton
                                .padding(.horizontal, 60)
                                .padding(.top, 8)
                        }

                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, 20)

                        projectsSection
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private func profileHeader(user: AppUser) -> some View {
        VStack(spacing: 12) {
            AvatarView(url: user.avatarUrl, size: 80, name: user.fullName)

            VStack(spacing: 4) {
                Text(user.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soulTextPrimary)

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(Color.soulAccent)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundStyle(Color.soulTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var friendshipButton: some View {
        switch friendshipStatus {
        case .none:
            SoulButton(title: "Add Friend") {
                sendRequest()
            }
        case .pending:
            SoulButton(title: "Request Sent", style: .secondary) {}
                .disabled(true)
        case .friends:
            SoulButton(title: "Friends", style: .secondary) {}
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Projects")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.soulTextPrimary)
                .padding(.horizontal, 20)

            if projects.isEmpty {
                Text("No projects yet")
                    .font(.subheadline)
                    .foregroundStyle(Color.soulTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(projects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            ProjectCard(project: project)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            user = try await FriendService.shared.fetchUser(id: userId)
            projects = try await ProjectService.shared.fetchUserProjects(userId: userId)

            if let currentUserId = authService.currentUser?.id {
                let friendships = try await FriendService.shared.fetchFriendships(userId: currentUserId)
                if let match = friendships.first(where: {
                    ($0.requesterId == currentUserId && $0.addresseeId == userId) ||
                    ($0.requesterId == userId && $0.addresseeId == currentUserId)
                }) {
                    friendshipId = match.id
                    friendshipStatus = match.status == .accepted ? .friends : .pending
                }
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }

    private func sendRequest() {
        guard let currentUserId = authService.currentUser?.id else { return }
        Task {
            try? await FriendService.shared.sendFriendRequest(from: currentUserId, to: userId)
            friendshipStatus = .pending
        }
    }
}
