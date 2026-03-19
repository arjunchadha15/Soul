import Foundation
import SwiftUI

@MainActor
final class TreeViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var updatesByProject: [UUID: [ProjectUpdate]] = [:]
    @Published var isLoading = false
    @Published var error: String?

    func loadTree(userId: UUID) async {
        isLoading = true
        error = nil
        do {
            projects = try await ProjectService.shared.fetchUserProjects(userId: userId)
            // Load updates for all projects concurrently
            try await withThrowingTaskGroup(of: (UUID, [ProjectUpdate]).self) { group in
                for project in projects {
                    group.addTask {
                        let updates = try await UpdateService.shared.fetchUpdates(for: project.id)
                        return (project.id, updates)
                    }
                }
                for try await (projectId, updates) in group {
                    updatesByProject[projectId] = updates
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var totalUpdates: Int {
        updatesByProject.values.reduce(0) { $0 + $1.count }
    }
}
