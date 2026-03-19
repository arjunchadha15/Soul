import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject var authService: AuthService
    let project: Project

    @StateObject private var updatesVM = UpdatesViewModel()
    @StateObject private var projectsVM = ProjectsViewModel()
    @State private var localProject: Project
    @State private var showNewUpdate = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) var dismiss

    var isOwner: Bool {
        authService.currentUser?.id == project.userId
    }

    init(project: Project) {
        self.project = project
        _localProject = State(initialValue: project)
    }

    var body: some View {
        ZStack {
            Color.soulBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Cover image
                    if let coverUrl = localProject.coverImageUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.soulCard
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                    }

                    // Project header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            StatusBadge(status: localProject.status)
                            Spacer()
                            Text("Started \(localProject.startDate.formatted())")
                                .font(.caption)
                                .foregroundStyle(Color.soulTextSecondary)
                        }

                        Text(localProject.title)
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundStyle(Color.soulTextPrimary)

                        if !localProject.description.isEmpty {
                            Text(localProject.description)
                                .font(.body)
                                .foregroundStyle(Color.soulTextSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 20)

                    // Timeline
                    timelineSection
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isOwner {
                    Button {
                        showNewUpdate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.soulBackground)
                            .padding(18)
                            .background(Color.soulAccent)
                            .clipShape(Circle())
                            .shadow(color: Color.soulAccent.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        statusMenu
                        Button("Edit Project") { showEditSheet = true }
                        Divider()
                        Button("Delete Project", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.soulTextPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewUpdate) {
            NewUpdateView(project: localProject) { update in
                updatesVM.updates.append(update)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProjectView(project: localProject) { title, description in
                localProject.title = title
                localProject.description = description
            }
        }
        .confirmationDialog(
            "Delete \"\(localProject.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await projectsVM.deleteProject(project: localProject)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the project and all its updates.")
        }
        .task {
            await updatesVM.loadUpdates(for: project.id)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if updatesVM.isLoading {
                ProgressView().tint(Color.soulAccent).padding(40)
            } else if updatesVM.updates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.soulTextSecondary)
                    Text("No updates yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.soulTextSecondary)
                    if isOwner {
                        Text("Tap + to post your first update.")
                            .font(.caption)
                            .foregroundStyle(Color.soulTextSecondary.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(updatesVM.updates) { update in
                        UpdateRow(update: update, isOwner: isOwner) {
                            Task { await updatesVM.deleteUpdate(update) }
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private var statusMenu: some View {
        Group {
            ForEach(ProjectStatus.allCases, id: \.self) { status in
                if status != localProject.status {
                    Button(status.displayName) {
                        Task {
                            await projectsVM.updateStatus(project: localProject, status: status)
                            localProject.status = status
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Update Row
struct UpdateRow: View {
    let update: ProjectUpdate
    let isOwner: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.soulAccent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
            }
            .frame(width: 32)
            .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 10) {
                Text(update.createdAt.formatted(style: .long))
                    .font(.caption)
                    .foregroundStyle(Color.soulAccent)

                if let mediaUrl = update.mediaUrl,
                   update.mediaType == .photo,
                   let url = URL(string: mediaUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.soulCard
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !update.text.isEmpty {
                    Text(update.text)
                        .font(.body)
                        .foregroundStyle(Color.soulTextPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .contextMenu {
                if isOwner {
                    Button("Delete Update", role: .destructive, action: onDelete)
                }
            }
        }
    }
}

// MARK: - Edit Project Sheet
struct EditProjectView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    var onSaved: (String, String) -> Void

    @State private var title: String
    @State private var description: String
    @State private var isLoading = false
    private let service = ProjectService.shared

    init(project: Project, onSaved: @escaping (String, String) -> Void) {
        self.project = project
        self.onSaved = onSaved
        _title = State(initialValue: project.title)
        _description = State(initialValue: project.description)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    SoulTextField(
                        placeholder: "Project Title",
                        text: $title,
                        autocapitalization: .words
                    )

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundStyle(Color.soulTextSecondary.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Color.soulTextPrimary)
                    }
                    .background(Color.soulCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    SoulButton(title: "Save Changes", isLoading: isLoading, isDisabled: title.isBlank, action: save)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.soulTextSecondary)
                }
            }
        }
    }

    private func save() {
        isLoading = true
        Task {
            try? await service.updateProject(
                id: project.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            onSaved(title, description)
            dismiss()
            isLoading = false
        }
    }
}
