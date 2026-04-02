//
//  RosterListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct RosterListView: View {
    let team: Team
    @State private var rosterVM = RosterViewModel()
    var body: some View {
        NavigationStack{
            ZStack{
                List(rosterVM.roster) {player in
                    NavigationLink{
                        PlayerListView(player: player)
                    } label:{
                        VStack(alignment: .leading){
                            Text(player.fullName)
                                .font(.title3)
                            Text(player.positionName)
                                .font(.subheadline)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle(team.name)
                .task{
                    await rosterVM.getData(for: team)
                }
                if rosterVM.isLoading{
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(4)
                }
            }
            
            
        }
    }
}

#Preview {
    RosterListView(team: Team(id: 133, name: "Athletics" , link: "https://statsapi.mlb.com/api/v1/teams/133/roster"))
}
