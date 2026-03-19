import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var treeVM = TreeViewModel()
    @State private var selectedProject: Project?
    @State private var selectedUpdate: ProjectUpdate?
    @State private var selectedUpdateProject: Project?
    @State private var showEditProfile = false
    @State private var showSignOutConfirm = false
    @State private var showNewProject = false

    private let engine = TreeLayoutEngine()

    var user: AppUser? { authService.currentUser }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color.soulBackground.ignoresSafeArea()

                    if treeVM.isLoading {
                        VStack {
                            Spacer()
                            ProgressView().tint(Color.soulAccent)
                            Text("Growing your tree…")
                                .font(.caption)
                                .foregroundStyle(Color.soulTextSecondary)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else if let user {
                        let layout = engine.compute(
                            user: user,
                            projects: treeVM.projects,
                            updatesByProject: treeVM.updatesByProject,
                            canvasWidth: geo.size.width
                        )

                        VStack(spacing: 0) {
                            profileHeader(user: user)
                            statsStrip
                            Divider()
                                .background(Color.white.opacity(0.07))

                            if treeVM.projects.isEmpty {
                                emptyTreeState
                            } else {
                                SoulTreeView(
                                    layout: layout,
                                    user: user,
                                    onBranchTap: { project in
                                        selectedProject = project
                                    },
                                    onNodeTap: { update, project in
                                        selectedUpdate = update
                                        selectedUpdateProject = project
                                    }
                                )
                            }
                        }
                    }

                    // Floating add button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showNewProject = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.soulBackground)
                                    .padding(18)
                                    .background(Color.soulAccent)
                                    .clipShape(Circle())
                                    .shadow(color: Color.soulAccent.opacity(0.35), radius: 14, y: 4)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Soul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Profile") { showEditProfile = true }
                        Divider()
                        Button("Sign Out", role: .destructive) { showSignOutConfirm = true }
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.soulTextSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectView { project in
                treeVM.projects.insert(project, at: 0)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project)
        }
        .sheet(item: $selectedUpdate) { update in
            if let project = selectedUpdateProject {
                UpdateDetailSheet(update: update, project: project)
            }
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { try? await authService.signOut() }
            }
        }
        .task {
            if let userId = user?.id {
                await treeVM.loadTree(userId: userId)
            }
        }
        .refreshable {
            if let userId = user?.id {
                await treeVM.loadTree(userId: userId)
            }
        }
    }

    // MARK: - Subviews

    private func profileHeader(user: AppUser) -> some View {
        HStack(spacing: 14) {
            AvatarView(url: user.avatarUrl, size: 48, name: user.fullName)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.headline)
                    .fontWeight(.bold)
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(treeVM.projects.filter { $0.status == .active }.count)",
                label: "Growing"
            )
            divider
            statItem(value: "\(treeVM.projects.count)", label: "Branches")
            divider
            statItem(value: "\(treeVM.totalUpdates)", label: "Moments")
        }
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 28)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.soulTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.soulTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyTreeState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 44))
                .foregroundStyle(Color.soulAccent.opacity(0.5))

            VStack(spacing: 8) {
                Text("Plant your first branch")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("Create a project and your Soul Tree will begin to grow.")
                    .font(.subheadline)
                    .foregroundStyle(Color.soulTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            SoulButton(title: "Create a Project") {
                showNewProject = true
            }
            .frame(width: 220)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Update Detail Sheet

struct UpdateDetailSheet: View {
    let update: ProjectUpdate
    let project: Project
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Project context
                        Text(project.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.soulAccent)

                        Text(update.createdAt.formatted(style: .long))
                            .font(.caption2)
                            .foregroundStyle(Color.soulTextSecondary)

                        if let mediaUrl = update.mediaUrl,
                           update.mediaType == .photo,
                           let url = URL(string: mediaUrl) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFit()
                                } else {
                                    Color.soulCard.frame(height: 200)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if !update.text.isEmpty {
                            Text(update.text)
                                .font(.body)
                                .foregroundStyle(Color.soulTextPrimary)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.soulAccent)
                }
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var fullName = ""
    @State private var bio = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    SoulTextField(
                        placeholder: "Full Name",
                        text: $fullName,
                        autocapitalization: .words
                    )

                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Bio (optional)")
                                .foregroundStyle(Color.soulTextSecondary.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        TextEditor(text: $bio)
                            .frame(minHeight: 80)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Color.soulTextPrimary)
                    }
                    .background(Color.soulCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    SoulButton(
                        title: "Save",
                        action: save,
                        isLoading: isLoading,
                        isDisabled: fullName.isBlank
                    )
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.soulTextSecondary)
                }
            }
            .onAppear {
                fullName = authService.currentUser?.fullName ?? ""
                bio = authService.currentUser?.bio ?? ""
            }
        }
    }

    private func save() {
        isLoading = true
        Task {
            try? await authService.updateProfile(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio.isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
            isLoading = false
        }
    }
}
