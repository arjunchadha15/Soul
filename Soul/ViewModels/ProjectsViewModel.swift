import Foundation
import SwiftUI

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = ProjectService.shared

    func loadProjects(userId: UUID) async {
        isLoading = true
        error = nil
        do {
            projects = try await service.fetchMyProjects(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createProject(
        userId: UUID,
        title: String,
        description: String,
        startDate: Date,
        coverImageData: Data? = nil
    ) async throws -> Project {
        var coverUrl: String? = nil
        let tempId = UUID()

        if let data = coverImageData {
            coverUrl = try await service.uploadCoverImage(data: data, projectId: tempId)
        }

        let project = try await service.createProject(
            userId: userId,
            title: title,
            description: description,
            startDate: startDate,
            coverImageUrl: coverUrl
        )

        projects.insert(project, at: 0)
        return project
    }

    func updateStatus(project: Project, status: ProjectStatus) async {
        do {
            try await service.updateProjectStatus(id: project.id, status: status)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].status = status
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func editProject(project: Project, title: String, description: String) async {
        do {
            try await service.updateProject(id: project.id, title: title, description: description)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx].title = title
                projects[idx].description = description
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteProject(project: Project) async {
        do {
            try await service.deleteProject(id: project.id)
            projects.removeAll { $0.id == project.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
