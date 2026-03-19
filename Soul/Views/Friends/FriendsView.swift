import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = FriendsViewModel()
    @State private var searchQuery = ""
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                List {
                    // Pending requests
                    if !viewModel.pendingReceived.isEmpty {
                        Section {
                            ForEach(viewModel.pendingReceived) { friend in
                                PendingRequestRow(friend: friend) {
                                    Task { await viewModel.acceptRequest(friend: friend) }
                                } onDecline: {
                                    Task { await viewModel.declineRequest(friend: friend) }
                                }
                            }
                        } header: {
                            Text("FRIEND REQUESTS")
                                .font(.caption)
                                .foregroundStyle(Color.soulTextSecondary)
                                .tracking(1.2)
                        }
                        .listRowBackground(Color.soulCard)
                    }

                    // Accepted friends
                    Section {
                        if viewModel.acceptedFriends.isEmpty {
                            Text("No friends yet")
                                .font(.subheadline)
                                .foregroundStyle(Color.soulTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.acceptedFriends) { friend in
                                NavigationLink(destination: UserProfileView(userId: friend.user.id)) {
                                    FriendRow(friend: friend)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Remove", role: .destructive) {
                                        Task { await viewModel.removeFriend(friend: friend) }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("FRIENDS")
                            .font(.caption)
                            .foregroundStyle(Color.soulTextSecondary)
                            .tracking(1.2)
                    }
                    .listRowBackground(Color.soulCard)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.soulAccent)
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                AddFriendView()
            }
        }
        .task {
            if let userId = authService.currentUser?.id {
                await viewModel.loadFriends(userId: userId)
            }
        }
        .refreshable {
            if let userId = authService.currentUser?.id {
                await viewModel.loadFriends(userId: userId)
            }
        }
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: friend.user.avatarUrl, size: 44, name: friend.user.fullName)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.user.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("@\(friend.user.username)")
                    .font(.caption)
                    .foregroundStyle(Color.soulTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pending Request Row
struct PendingRequestRow: View {
    let friend: Friend
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: friend.user.avatarUrl, size: 44, name: friend.user.fullName)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.user.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("@\(friend.user.username)")
                    .font(.caption)
                    .foregroundStyle(Color.soulTextSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.soulTextSecondary)
                        .padding(8)
                        .background(Color.soulBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.soulBackground)
                        .padding(8)
                        .background(Color.soulAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Friend View
struct AddFriendView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FriendsViewModel()
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    SoulTextField(
                        placeholder: "Search by username",
                        text: $query,
                        autocapitalization: .never
                    )
                    .padding(.horizontal, 20)
                    .onChange(of: query) {
                        if let userId = authService.currentUser?.id {
                            Task {
                                await viewModel.searchUsers(query: query, currentUserId: userId)
                            }
                        }
                    }

                    if viewModel.isSearching {
                        ProgressView().tint(Color.soulAccent)
                    } else if !viewModel.searchResults.isEmpty {
                        List(viewModel.searchResults) { user in
                            SearchResultRow(user: user) {
                                if let userId = authService.currentUser?.id {
                                    Task {
                                        await viewModel.sendRequest(from: userId, to: user)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    } else if !query.isEmpty {
                        Text("No users found")
                            .foregroundStyle(Color.soulTextSecondary)
                            .padding(.top, 32)
                    }

                    Spacer()
                }
                .padding(.top, 8)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.soulTextSecondary)
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let user: AppUser
    let onAdd: () -> Void
    @State private var requestSent = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: user.avatarUrl, size: 44, name: user.fullName)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.soulTextPrimary)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(Color.soulTextSecondary)
            }

            Spacer()

            Button {
                onAdd()
                requestSent = true
            } label: {
                Text(requestSent ? "Sent" : "Add")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(requestSent ? Color.soulTextSecondary : Color.soulBackground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(requestSent ? Color.soulCard : Color.soulAccent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(requestSent)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.soulCard)
    }
}
