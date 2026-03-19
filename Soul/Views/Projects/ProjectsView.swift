import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showNewProject = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.projects.isEmpty {
                        ProgressView().tint(Color.soulAccent)
                    } else if viewModel.projects.isEmpty {
                        emptyState
                    } else {
                        projectList
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewProject = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.soulAccent)
                    }
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectView { project in
                    viewModel.projects.insert(project, at: 0)
                }
            }
        }
        .task {
            if let userId = authService.currentUser?.id {
                await viewModel.loadProjects(userId: userId)
            }
        }
        .refreshable {
            if let userId = authService.currentUser?.id {
                await viewModel.loadProjects(userId: userId)
            }
        }
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.projects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(Color.soulTextSecondary)

            Text("No projects yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.soulTextPrimary)

            Text("Create your first project to start\ndocumenting your journey.")
                .font(.subheadline)
                .foregroundStyle(Color.soulTextSecondary)
                .multilineTextAlignment(.center)

            SoulButton(title: "Create Project") {
                showNewProject = true
            }
            .frame(width: 200)
        }
    }
}
