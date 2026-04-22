import SwiftUI

struct FrontListView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TeamListView()
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Teams")
            }

            NavigationStack {
                LeadersListView()
            }
            .tabItem {
                Image(systemName: "list.number")
                Text("Leaders")
            }

            NavigationStack {
                SearchListView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }

            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }
        }
    }
}

#Preview {
    FrontListView()
}
