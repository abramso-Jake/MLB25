import SwiftUI

enum TeamSortMode: String, CaseIterable {
    case alphabetical = "A-Z"
    case standings = "Standings"
}

struct TeamListView: View {
    @State private var teamsVM = TeamViewModel()
    @State private var sortMode: TeamSortMode = .alphabetical
    @State private var searchText = ""

    var filteredTeams: [Team] {
        let filtered: [Team]

        if searchText.isEmpty {
            filtered = teamsVM.teams
        } else {
            filtered = teamsVM.teams.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortMode {
        case .alphabetical:
            return filtered.sorted { $0.name < $1.name }

        case .standings:
            return filtered.sorted {
                winningPercentage(from: teamsVM.recordsByTeamID[$0.id] ?? "0-0")
                >
                winningPercentage(from: teamsVM.recordsByTeamID[$1.id] ?? "0-0")
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text("MLB Teams")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)

                    TextField("Search teams", text: $searchText)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
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

                List(filteredTeams) { team in
                    NavigationLink {
                        TeamDetailListView(
                            team: team,
                            record: teamsVM.recordsByTeamID[team.id] ?? "--"
                        )
                    } label: {
                        HStack {
                            Text("\(team.name):")
                            Text(teamsVM.recordsByTeamID[team.id] ?? "--")
                                .foregroundStyle(.primary)
                        }
                        .font(.title3)
                    }
                }
                .listStyle(.plain)
            }
            .task {
                await teamsVM.getData()
                await teamsVM.getRecords(for: 2026)
            }

            if teamsVM.isLoading {
                ProgressView()
                    .tint(.red)
                    .scaleEffect(4)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Picker("Sort", selection: $sortMode) {
                ForEach(TeamSortMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

func winningPercentage(from record: String) -> Double {
    let parts = record.split(separator: "-")
    guard parts.count >= 2,
          let wins = Double(parts[0]),
          let losses = Double(parts[1]) else {
        return 0
    }

    let games = wins + losses
    return games == 0 ? 0 : wins / games
}

#Preview {
    NavigationStack {
        TeamListView()
    }
}
