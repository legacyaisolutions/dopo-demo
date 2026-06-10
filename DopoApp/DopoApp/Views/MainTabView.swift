import SwiftUI
import UIKit

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
                    if let uiImage = UIImage(named: "Icons/collections-icon")?.withRenderingMode(.alwaysTemplate) {
                        Image(uiImage: uiImage)
                    } else {
                        Image(systemName: "square.on.square.fill")
                    }
                    Text("Collections")
                }
                .tag(1)

            DiscoverView()
                .tabItem {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("Discover")
                }
                .tag(2)

            IngestView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Save")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.dopoAccent)
    }
}
