//
//  ContentView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

enum TeamSortMode: String, CaseIterable {
    case alphabetical = "A-Z"
    case standings = "Standings"
}

struct TeamListView: View {
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
    @State private var teamsVM = TeamViewModel()
    @State private var sortMode: TeamSortMode = .alphabetical
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            ZStack{
                List(filteredTeams) { team in
                    NavigationLink {
                        TeamDetailListView(team: team, record: teamsVM.recordsByTeamID[team.id] ?? "--")
                    } label:{
                        Text("\(team.name): \(teamsVM.recordsByTeamID[team.id] ?? "--")")
                            .font(.title2)
                    }
                }
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search teams"
                )
                .listStyle(.plain)
                .navigationTitle("MLB Teams:")
                .task{
                    await teamsVM.getData()
                    await teamsVM.getRecords(for: 2026)
                }
                if teamsVM.isLoading{
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
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "chevron.left", role: .close) {
                        dismiss()
                    }
                }
            }
           
            
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
    TeamListView()
}
