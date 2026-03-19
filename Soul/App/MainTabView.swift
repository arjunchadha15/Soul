import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(1)

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Soul", systemImage: "leaf.fill")
                }
                .tag(3)
        }
        .tint(Color.soulAccent)
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
