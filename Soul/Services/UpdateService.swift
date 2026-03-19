import Foundation
import Supabase

@MainActor
final class UpdateService {
    static let shared = UpdateService()
    private init() {}

    func fetchUpdates(for projectId: UUID) async throws -> [ProjectUpdate] {
        let updates: [ProjectUpdate] = try await supabase
            .from("updates")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        return updates
    }

    func createUpdate(
        projectId: UUID,
        userId: UUID,
        text: String,
        mediaUrl: String? = nil,
        mediaType: MediaType = .none
    ) async throws -> ProjectUpdate {
        struct NewUpdate: Encodable {
            let projectId: UUID
            let userId: UUID
            let text: String
            let mediaUrl: String?
            let mediaType: String
            enum CodingKeys: String, CodingKey {
                case projectId = "project_id"
                case userId = "user_id"
                case text
                case mediaUrl = "media_url"
                case mediaType = "media_type"
            }
        }

        let payload = NewUpdate(
            projectId: projectId,
            userId: userId,
            text: text,
            mediaUrl: mediaUrl,
            mediaType: mediaType.rawValue
        )

        let update: ProjectUpdate = try await supabase
            .from("updates")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return update
    }

    func deleteUpdate(id: UUID) async throws {
        try await supabase
            .from("updates")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func uploadMedia(data: Data, updateId: UUID, isVideo: Bool) async throws -> String {
        let ext = isVideo ? "mp4" : "jpg"
        let contentType = isVideo ? "video/mp4" : "image/jpeg"
        let path = "updates/\(updateId.uuidString).\(ext)"
        try await supabase.storage
            .from("project-media")
            .upload(path, data: data, options: FileOptions(contentType: contentType))
        let url = try supabase.storage
            .from("project-media")
            .getPublicURL(path: path)
        return url.absoluteString
    }

    // Fetch feed updates from friends
    func fetchFeedUpdates(friendIds: [UUID]) async throws -> [ProjectUpdate] {
        guard !friendIds.isEmpty else { return [] }
        let ids = friendIds.map { $0.uuidString }
        let updates: [ProjectUpdate] = try await supabase
            .from("updates")
            .select()
            .in("user_id", values: ids)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return updates
    }
}
