import Foundation
import SwiftUI

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var acceptedFriends: [Friend] = []
    @Published var pendingReceived: [Friend] = []
    @Published var pendingSent: [Friend] = []
    @Published var searchResults: [AppUser] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var error: String?

    private let service = FriendService.shared

    func loadFriends(userId: UUID) async {
        isLoading = true
        error = nil
        do {
            let friendships = try await service.fetchFriendships(userId: userId)

            var accepted: [Friend] = []
            var received: [Friend] = []
            var sent: [Friend] = []

            for friendship in friendships {
                let otherId = friendship.requesterId == userId
                    ? friendship.addresseeId
                    : friendship.requesterId

                let user = try await service.fetchUser(id: otherId)
                let friend = Friend(id: friendship.id, friendship: friendship, user: user)

                switch friendship.status {
                case .accepted:
                    accepted.append(friend)
                case .pending:
                    if friendship.requesterId == userId {
                        sent.append(friend)
                    } else {
                        received.append(friend)
                    }
                }
            }

            acceptedFriends = accepted
            pendingReceived = received
            pendingSent = sent
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func searchUsers(query: String, currentUserId: UUID) async {
        guard !query.isBlank else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            let results = try await service.searchUsers(username: query)
            searchResults = results.filter { $0.id != currentUserId }
        } catch {
            self.error = error.localizedDescription
        }
        isSearching = false
    }

    func sendRequest(from userId: UUID, to targetUser: AppUser) async {
        do {
            try await service.sendFriendRequest(from: userId, to: targetUser.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func acceptRequest(friend: Friend) async {
        do {
            try await service.acceptFriendRequest(friendshipId: friend.friendship.id)
            pendingReceived.removeAll { $0.id == friend.id }
            acceptedFriends.append(Friend(
                id: friend.id,
                friendship: Friendship(
                    id: friend.friendship.id,
                    requesterId: friend.friendship.requesterId,
                    addresseeId: friend.friendship.addresseeId,
                    status: .accepted,
                    createdAt: friend.friendship.createdAt
                ),
                user: friend.user
            ))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func declineRequest(friend: Friend) async {
        do {
            try await service.declineFriendRequest(friendshipId: friend.friendship.id)
            pendingReceived.removeAll { $0.id == friend.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFriend(friend: Friend) async {
        do {
            try await service.removeFriend(friendshipId: friend.friendship.id)
            acceptedFriends.removeAll { $0.id == friend.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
