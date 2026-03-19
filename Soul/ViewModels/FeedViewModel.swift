import Foundation
import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let friendService = FriendService.shared
    private let updateService = UpdateService.shared
    private let projectService = ProjectService.shared

    func loadFeed(userId: UUID) async {
        isLoading = true
        error = nil
        do {
            let friendIds = try await friendService.fetchAcceptedFriendIds(userId: userId)
            guard !friendIds.isEmpty else {
                feedItems = []
                isLoading = false
                return
            }

            let updates = try await updateService.fetchFeedUpdates(friendIds: friendIds)

            var items: [FeedItem] = []
            var projectCache: [UUID: Project] = [:]
            var userCache: [UUID: AppUser] = [:]

            for update in updates {
                // Fetch project
                let project: Project
                if let cached = projectCache[update.projectId] {
                    project = cached
                } else {
                    project = try await projectService.fetchProject(id: update.projectId)
                    projectCache[update.projectId] = project
                }

                // Fetch user
                let user: AppUser
                if let cached = userCache[update.userId] {
                    user = cached
                } else {
                    user = try await friendService.fetchUser(id: update.userId)
                    userCache[update.userId] = user
                }

                items.append(FeedItem(id: update.id, update: update, project: project, user: user))
            }

            feedItems = items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
