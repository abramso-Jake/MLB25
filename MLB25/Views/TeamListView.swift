//
//  ContentView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct TeamListView: View {
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return teamsVM.teams
        } else {
            return teamsVM.teams.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    @State private var teamsVM = TeamViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            ZStack{
                List(filteredTeams) { team in
                    NavigationLink {
                        TeamDetailListView(team: team, record: teamsVM.recordsByTeamID[team.id] ?? "--")
                    } label:{
                        Text("\(teamsVM.returnIndex(of: team)). \(team.name): \(teamsVM.recordsByTeamID[team.id] ?? "--")")
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

#Preview {
    TeamListView()
}
