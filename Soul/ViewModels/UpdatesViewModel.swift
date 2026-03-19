import Foundation
import SwiftUI

@MainActor
final class UpdatesViewModel: ObservableObject {
    @Published var updates: [ProjectUpdate] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = UpdateService.shared

    func loadUpdates(for projectId: UUID) async {
        isLoading = true
        error = nil
        do {
            updates = try await service.fetchUpdates(for: projectId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func postUpdate(
        projectId: UUID,
        userId: UUID,
        text: String,
        mediaData: Data? = nil,
        isVideo: Bool = false
    ) async throws {
        let tempId = UUID()
        var mediaUrl: String? = nil
        var mediaType: MediaType = .none

        if let data = mediaData {
            mediaUrl = try await service.uploadMedia(data: data, updateId: tempId, isVideo: isVideo)
            mediaType = isVideo ? .video : .photo
        }

        let update = try await service.createUpdate(
            projectId: projectId,
            userId: userId,
            text: text,
            mediaUrl: mediaUrl,
            mediaType: mediaType
        )

        updates.append(update)
    }

    func deleteUpdate(_ update: ProjectUpdate) async {
        do {
            try await service.deleteUpdate(id: update.id)
            updates.removeAll { $0.id == update.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
