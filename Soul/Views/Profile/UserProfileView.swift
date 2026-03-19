import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authService: AuthService
    let userId: UUID

    @State private var user: AppUser?
    @StateObject private var treeVM = TreeViewModel()
    @State private var isLoading = true
    @State private var friendshipStatus: FriendshipButtonState = .none
    @State private var selectedProject: Project?
    @State private var selectedUpdate: ProjectUpdate?
    @State private var selectedUpdateProject: Project?

    private let engine = TreeLayoutEngine()

    enum FriendshipButtonState { case none, pending, friends }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Color.soulAccent)
                } else if let user {
                    let layout = engine.compute(
                        user: user,
                        projects: treeVM.projects,
                        updatesByProject: treeVM.updatesByProject,
                        canvasWidth: geo.size.width
                    )

                    VStack(spacing: 0) {
                        profileHeader(user: user)

                        if authService.currentUser?.id != userId {
                            friendshipButton
                                .padding(.horizontal, 60)
                                .padding(.bottom, 10)
                        }

                        Divider().background(Color.white.opacity(0.07))

                        if treeVM.projects.isEmpty {
                            Spacer()
                            Text("No projects yet")
                                .foregroundStyle(Color.soulTextSecondary)
                            Spacer()
                        } else {
                            SoulTreeView(
                                layout: layout,
                                user: user,
                                onBranchTap: { selectedProject = $0 },
                                onNodeTap: { update, project in
                                    selectedUpdate = update
                                    selectedUpdateProject = project
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProject) { ProjectDetailView(project: $0) }
        .sheet(item: $selectedUpdate) { update in
            if let project = selectedUpdateProject {
                UpdateDetailSheet(update: update, project: project)
            }
        }
        .task { await loadProfile() }
    }

    private func profileHeader(user: AppUser) -> some View {
        HStack(spacing: 14) {
            AvatarView(url: user.avatarUrl, size: 48, name: user.fullName)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.headline).fontWeight(.bold)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(Color.soulAccent)
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(Color.soulTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(treeVM.projects.count)")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("branches")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.soulTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var friendshipButton: some View {
        switch friendshipStatus {
        case .none:
            SoulButton(title: "Add Friend", action: sendRequest)

        case .pending:
            SoulButton(title: "Request Sent", style: .secondary) {}
                .disabled(true)
        case .friends:
            SoulButton(title: "Friends ✓", style: .secondary) {}
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            user = try await FriendService.shared.fetchUser(id: userId)
            await treeVM.loadTree(userId: userId)

            if let currentUserId = authService.currentUser?.id {
                let friendships = try await FriendService.shared.fetchFriendships(userId: currentUserId)
                if let match = friendships.first(where: {
                    ($0.requesterId == currentUserId && $0.addresseeId == userId) ||
                    ($0.requesterId == userId && $0.addresseeId == currentUserId)
                }) {
                    friendshipStatus = match.status == .accepted ? .friends : .pending
                }
            }
        } catch { }
        isLoading = false
    }

    private func sendRequest() {
        guard let currentId = authService.currentUser?.id else { return }
        Task {
            try? await FriendService.shared.sendFriendRequest(from: currentId, to: userId)
            friendshipStatus = .pending
        }
    }
}
