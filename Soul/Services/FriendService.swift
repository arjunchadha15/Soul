import Foundation
import Supabase

@MainActor
final class FriendService {
    static let shared = FriendService()
    private init() {}

    func searchUsers(username: String) async throws -> [AppUser] {
        let users: [AppUser] = try await supabase
            .from("users")
            .select()
            .ilike("username", pattern: "%\(username)%")
            .limit(20)
            .execute()
            .value
        return users
    }

    func fetchFriendships(userId: UUID) async throws -> [Friendship] {
        let friendships: [Friendship] = try await supabase
            .from("friendships")
            .select()
            .or("requester_id.eq.\(userId.uuidString),addressee_id.eq.\(userId.uuidString)")
            .execute()
            .value
        return friendships
    }

    func sendFriendRequest(from requesterId: UUID, to addresseeId: UUID) async throws {
        struct NewFriendship: Encodable {
            let requesterId: UUID
            let addresseeId: UUID
            let status: String
            enum CodingKeys: String, CodingKey {
                case requesterId = "requester_id"
                case addresseeId = "addressee_id"
                case status
            }
        }
        try await supabase
            .from("friendships")
            .insert(NewFriendship(requesterId: requesterId, addresseeId: addresseeId, status: "pending"))
            .execute()
    }

    func acceptFriendRequest(friendshipId: UUID) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        try await supabase
            .from("friendships")
            .update(StatusUpdate(status: "accepted"))
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    func declineFriendRequest(friendshipId: UUID) async throws {
        try await supabase
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    func removeFriend(friendshipId: UUID) async throws {
        try await supabase
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    func fetchAcceptedFriendIds(userId: UUID) async throws -> [UUID] {
        let friendships = try await fetchFriendships(userId: userId)
        return friendships
            .filter { $0.status == .accepted }
            .map { f in
                f.requesterId == userId ? f.addresseeId : f.requesterId
            }
    }

    func fetchUser(id: UUID) async throws -> AppUser {
        let user: AppUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return user
    }

    func fetchUser(username: String) async throws -> AppUser {
        let user: AppUser = try await supabase
            .from("users")
            .select()
            .eq("username", value: username)
            .single()
            .execute()
            .value
        return user
    }
}
