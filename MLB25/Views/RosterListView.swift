//
//  RosterListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct RosterListView: View {
    let team: Team
    let record: String
    @State private var rosterVM = RosterViewModel()

    var pitchers: [Roster] {
        rosterVM.roster.filter { $0.positionAbbreviation == "P" }
    }

    var hitters: [Roster] {
        rosterVM.roster.filter { $0.positionAbbreviation != "P" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section(header:
                        Text("Pitchers:")
                            .font(.title3)
                            .tint(.black)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    ){
                        ForEach(pitchers) { player in
                            NavigationLink {
                                PlayerListView(player: player, entry: .roster)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(player.fullName)
                                        .font(.title3)
                                    Text(player.positionName)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    Section(header:
                        Text("Hitters:")
                            .font(.title3)
                            .tint(.black)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    ){
                        ForEach(hitters) { player in
                            NavigationLink {
                                PlayerListView(player: player, entry: .roster)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(player.fullName)
                                        .font(.title3)
                                    Text(player.positionName)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("") // suppress default
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("\(team.name): \(record)")
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                
                .task {
                    await rosterVM.getData(for: team)
                }

                if rosterVM.isLoading {
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(4)
                }
            }
        }
    }
}

#Preview {
    RosterListView(team: Team(id: 133, name: "Athletics" , link: "https://statsapi.mlb.com/api/v1/teams/133/roster"), record: "8-5")
}
