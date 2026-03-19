import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var projectsVM = ProjectsViewModel()
    @State private var showEditProfile = false
    @State private var showSignOutConfirm = false

    var user: AppUser? { authService.currentUser }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        profileHeader
                        statsRow
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, 20)
                        projectsSection
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Profile") { showEditProfile = true }
                        Divider()
                        Button("Sign Out", role: .destructive) {
                            showSignOutConfirm = true
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.soulTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            }
        }
        .task {
            if let userId = user?.id {
                await projectsVM.loadProjects(userId: userId)
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            AvatarView(url: user?.avatarUrl, size: 80, name: user?.fullName ?? "")

            VStack(spacing: 4) {
                Text(user?.fullName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soulTextPrimary)

                Text("@\(user?.username ?? "")")
                    .font(.subheadline)
                    .foregroundStyle(Color.soulAccent)

                if let bio = user?.bio, !bio.isEmpty {
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

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(projectsVM.projects.filter { $0.status == .active }.count)",
                label: "Active"
            )
            Divider()
                .frame(height: 32)
                .background(Color.white.opacity(0.1))
            statItem(
                value: "\(projectsVM.projects.count)",
                label: "Projects"
            )
            Divider()
                .frame(height: 32)
                .background(Color.white.opacity(0.1))
            statItem(
                value: "\(projectsVM.projects.filter { $0.status == .completed }.count)",
                label: "Done"
            )
        }
        .padding(.vertical, 12)
        .background(Color.soulCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.soulTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.soulTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Projects")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.soulTextPrimary)
                .padding(.horizontal, 20)

            if projectsVM.isLoading {
                ProgressView().tint(Color.soulAccent).padding()
            } else if projectsVM.projects.isEmpty {
                Text("No projects yet")
                    .font(.subheadline)
                    .foregroundStyle(Color.soulTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(projectsVM.projects) { project in
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
