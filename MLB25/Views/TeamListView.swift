//
//  ContentView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct TeamListView: View {
    @State private var teamsVM = TeamViewModel()
    @Environment(\.dismiss) var dismiss
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
