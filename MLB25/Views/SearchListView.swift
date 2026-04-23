import SwiftUI

struct SearchListView: View {
    @State private var searchVM = SearchViewModel()

    var body: some View {
        VStack(spacing: 12) {
            Text("Player Search")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)

                TextField("Search player", text: $searchVM.searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchVM.searchText) {
                        Task {
                            if searchVM.searchText.count >= 2 {
                                await searchVM.searchPlayers()
                            } else {
                                searchVM.results = []
                                searchVM.errorMessage = ""
                            }
                        }
                    }

                if !searchVM.searchText.isEmpty {
                    Button {
                        searchVM.searchText = ""
                        searchVM.results = []
                        searchVM.errorMessage = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)

            if !searchVM.results.isEmpty {
                Text("\(searchVM.results.count) players found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            if searchVM.searchText.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)

                    Text("Search for an MLB player")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text("Type at least 2 letters to search.")
                        .foregroundStyle(.secondary)
                }
                Spacer()

            } else if searchVM.searchText.count == 1 {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)

                    Text("Keep typing")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("Type at least 2 letters to search.")
                        .foregroundStyle(.secondary)
                }
                Spacer()

            } else if searchVM.isLoading {
                Spacer()
                ProgressView()
                    .tint(.red)
                    .scaleEffect(4)
                Spacer()

            } else if !searchVM.errorMessage.isEmpty {
                Spacer()
                Text(searchVM.errorMessage)
                    .foregroundStyle(.red)
                Spacer()

            } else if searchVM.results.isEmpty {
                Spacer()
                Text("No players found.")
                    .foregroundStyle(.secondary)
                Spacer()

            } else {
                List(searchVM.results) { player in
                    NavigationLink {
                        PlayerListView(
                            player: Roster(
                                person: Person(
                                    id: player.id,
                                    fullName: player.fullName,
                                    link: player.link
                                ),
                                position: Position(
                                    name: player.positionName,
                                    abbreviation: player.positionAbbreviation
                                )
                            ),
                            entry: .search
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.fullName)
                                .font(.headline)

                            Text("\(player.positionName) • \(player.positionAbbreviation)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchListView()
    }
}
