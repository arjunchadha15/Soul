import Foundation
import Supabase

@MainActor
final class ProjectService {
    static let shared = ProjectService()
    private init() {}

    func fetchMyProjects(userId: UUID) async throws -> [Project] {
        let projects: [Project] = try await supabase
            .from("projects")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return projects
    }

    func fetchProject(id: UUID) async throws -> Project {
        let project: Project = try await supabase
            .from("projects")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return project
    }

    func fetchUserProjects(userId: UUID) async throws -> [Project] {
        let projects: [Project] = try await supabase
            .from("projects")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return projects
    }

    func createProject(
        userId: UUID,
        title: String,
        description: String,
        startDate: Date,
        coverImageUrl: String? = nil
    ) async throws -> Project {
        struct NewProject: Encodable {
            let userId: UUID
            let title: String
            let description: String
            let status: String
            let startDate: String
            let coverImageUrl: String?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
                case description
                case status
                case startDate = "start_date"
                case coverImageUrl = "cover_image_url"
            }
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: startDate)

        let newProject = NewProject(
            userId: userId,
            title: title,
            description: description,
            status: "active",
            startDate: dateString,
            coverImageUrl: coverImageUrl
        )

        let project: Project = try await supabase
            .from("projects")
            .insert(newProject)
            .select()
            .single()
            .execute()
            .value
        return project
    }

    func updateProjectStatus(id: UUID, status: ProjectStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        try await supabase
            .from("projects")
            .update(StatusUpdate(status: status.rawValue))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateProject(id: UUID, title: String, description: String) async throws {
        struct ProjectEdit: Encodable {
            let title: String
            let description: String
        }
        try await supabase
            .from("projects")
            .update(ProjectEdit(title: title, description: description))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteProject(id: UUID) async throws {
        try await supabase
            .from("projects")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func uploadCoverImage(data: Data, projectId: UUID) async throws -> String {
        let path = "covers/\(projectId.uuidString).jpg"
        try await supabase.storage
            .from("project-media")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        let url = try supabase.storage
            .from("project-media")
            .getPublicURL(path: path)
        return url.absoluteString
    }
}
