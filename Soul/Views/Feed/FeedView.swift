import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedItem: FeedItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.feedItems.isEmpty {
                        ProgressView()
                            .tint(Color.soulAccent)
                    } else if viewModel.feedItems.isEmpty {
                        emptyState
                    } else {
                        feedList
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                if let userId = authService.currentUser?.id {
                    await viewModel.loadFeed(userId: userId)
                }
            }
        }
        .task {
            if let userId = authService.currentUser?.id {
                await viewModel.loadFeed(userId: userId)
            }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.feedItems) { item in
                    NavigationLink(destination: ProjectDetailView(project: item.project)) {
                        FeedCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundStyle(Color.soulTextSecondary)

            Text("Your feed is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.soulTextPrimary)

            Text("Add some friends to see their project updates here.")
                .font(.subheadline)
                .foregroundStyle(Color.soulTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
