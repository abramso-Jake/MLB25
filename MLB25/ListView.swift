//
//  ContentView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct ListView: View {
    @State private var teamsVM = TeamViewModel()
    var body: some View {
        NavigationStack{
            ZStack{
                List(teamsVM.teams) { team in
                    NavigationLink {
                        RosterListView(team: team)
                    } label:{
                        Text("\(teamsVM.returnIndex(of: team)). \(team.name)")
                            .font(.title2)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("MLB Teams:")
                .task{
                    await teamsVM.getData()
                }
                if teamsVM.isLoading{
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(4)
                }
            }

            
        }
        
    }
    
}

#Preview {
    ListView()
}
