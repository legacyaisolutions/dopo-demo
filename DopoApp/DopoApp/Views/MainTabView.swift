import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Library")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Collections")
                }
                .tag(1)

            IngestView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Save")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(.dopoAccent)
    }
}
