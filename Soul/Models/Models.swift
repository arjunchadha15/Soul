import Foundation

// MARK: - User
struct AppUser: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var fullName: String
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
    }
}

// MARK: - Project
struct Project: Codable, Identifiable, Equatable {
    let id: UUID
    var userId: UUID
    var title: String
    var description: String
    var status: ProjectStatus
    var startDate: Date
    var coverImageUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case status
        case startDate = "start_date"
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
    }
}

enum ProjectStatus: String, Codable, CaseIterable {
    case active
    case paused
    case completed

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }

    var color: String {
        switch self {
        case .active: return "StatusActive"
        case .paused: return "StatusPaused"
        case .completed: return "StatusCompleted"
        }
    }
}

// MARK: - Update
struct ProjectUpdate: Codable, Identifiable, Equatable {
    let id: UUID
    var projectId: UUID
    var userId: UUID
    var text: String
    var mediaUrl: String?
    var mediaType: MediaType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case userId = "user_id"
        case text
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
    }
}

enum MediaType: String, Codable {
    case photo
    case video
    case none
}

// MARK: - Friendship
struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    var requesterId: UUID
    var addresseeId: UUID
    var status: FriendshipStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
    }
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
}

// MARK: - Feed Item (joined data)
struct FeedItem: Identifiable, Equatable {
    let id: UUID
    let update: ProjectUpdate
    let project: Project
    let user: AppUser

    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Friend with User
struct Friend: Identifiable, Equatable {
    let id: UUID
    let friendship: Friendship
    let user: AppUser

    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
    }
}
