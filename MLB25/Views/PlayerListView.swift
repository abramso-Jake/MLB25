//
//  PlayerListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct PlayerListView: View {
    let player: Roster
    @State private var playerVM = PlayerViewModel()
    @State private var selectedStat: StatSelection = .season2025
    var body: some View {
        NavigationStack{
            VStack{
                Picker("Stats", selection: $selectedStat){
                    ForEach(StatSelection.allCases, id: \.displayName){option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                HStack{
                    PlayerImage
                        .padding()
                    if playerVM.isLoading{
                        ProgressView()
                            .tint(.red)
                            .scaleEffect(4)
                    } else if let stat = playerVM.statLine {
                        if player.positionAbbreviation == "P"{
                            VStack(alignment: .leading){
                                Text("Games Played: \(stat.gamesPlayed ?? 0)")
                                Text("IP: \(stat.inningsPitched ?? "-")")
                                Text("ERA: \(stat.era ?? "-")")
                                Text("WHIP: \(stat.whip ?? "-")")
                                Text("W: \(stat.wins ?? 0)")
                                Text("L: \(stat.losses ?? 0)")
                                Text("SO: \(stat.strikeOuts ?? 0)")
                                let sv = (stat.saves ?? 0)
                                if sv >= 1{
                                    Text("SV: \(sv)")
                                }
                                Text("OBA: \(stat.avg ?? "-")")
                                Text("Walks: \(stat.baseOnBalls ?? 0)")
                                let cg = (stat.completeGames ?? 0)
                                if cg >= 1{
                                    Text("CG: \(cg)")
                                }
                                let sho = (stat.shutouts ?? 0)
                                if sho >= 1{
                                    Text("SHO: \(sho)")
                                }
                                let pick = (stat.pickoffs ?? 0)
                                if pick >= 5{
                                    Text("Pickoffs: \(pick)")
                                }
                            }
                            .font(.title)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        } else if (player.positionAbbreviation == "TWP"){
                            VStack(alignment: .leading){
                                if let pitching = playerVM.secondStatLine {
                                    Text("Pitching:")
                                        .font(.title3)
                                        .fontWeight(.black)
                                    Text("IP: \(pitching.inningsPitched ?? "-")")
                                    Text("ERA: \(pitching.era ?? "-")")
                                    Text("WHIP: \(pitching.whip ?? "-")")
                                    Text("W: \(pitching.wins ?? 0)")
                                    Text("L: \(pitching.losses ?? 0)")
                                    Text("SO: \(pitching.strikeOuts ?? 0)")
                                    Text("OBA: \(pitching.avg ?? "-")")
                                    Text("Walks: \(pitching.baseOnBalls ?? 0)")
                                }
                                if let hitting = playerVM.statLine{
                                    Text("")
                                    Text("Hitting:")
                                        .font(.title3)
                                        .fontWeight(.black)
                                    Text("At Bats: \(hitting.atBats ?? 0)")
                                    Text("Walks: \(hitting.baseOnBalls ?? 0)")
                                    Text("Hits: \(hitting.hits ?? 0)")
                                    let sb = (hitting.stolenBases ?? 0)
                                    if sb >= 20{
                                        Text("Stolen Bases: \(hitting.stolenBases ?? 0)")
                                    }
                                    Text("AVG: \(hitting.avg ?? "-")")
                                    Text("HR: \(hitting.homeRuns ?? 0)")
                                    Text("RBI: \(hitting.rbi ?? 0)")
                                    Text("OPS: \(hitting.ops ?? "-")")
                                    Text("SO: \(hitting.strikeOuts ?? 0)")
                                }
                            }
                        } else{
                            VStack(alignment: .leading) {
                                Text("Games Played: \(stat.gamesPlayed ?? 0)")
                                Text("At Bats: \(stat.atBats ?? 0)")
                                Text("Walks: \(stat.baseOnBalls ?? 0)")
                                Text("Hits: \(stat.hits ?? 0)")
                                let sb = (stat.stolenBases ?? 0)
                                if sb >= 20{
                                    Text("Stolen Bases: \(stat.stolenBases ?? 0)")
                                }
                                Text("AVG: \(stat.avg ?? "-")")
                                Text("HR: \(stat.homeRuns ?? 0)")
                                Text("RBI: \(stat.rbi ?? 0)")
                                Text("OPS: \(stat.ops ?? "-")")
                                Text("SO: \(stat.strikeOuts ?? 0)")
                            }
                            .font(.title)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        }
                    } else {
                        Text(playerVM.errorMessage.isEmpty ? "No Stats Available." : playerVM.errorMessage)
                    }
                   
                }
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("") // suppress default
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(player.fullName)- \(player.positionAbbreviation)")
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .task{
                await playerVM.getData(for: player, selection: selectedStat)
            }
            .onChange(of: selectedStat){
                Task{
                    await playerVM.getData(for: player, selection: selectedStat)
                }
            }
            
        }
    }
    
}

extension PlayerListView{
    var PlayerImage: some View{
        AsyncImage(url: player.headshotURL) { phase in
            if let image = phase.image{
                image
                    .resizable()
                    .scaledToFit()
                    .background(.white)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8, x: 5, y: 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    }
            } else if phase.error != nil{
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .background(.white)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8, x: 5, y: 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    }
            } else {
//                        RoundedRectangle(cornerRadius: 10)
//                            .foregroundStyle(.clear)
                ProgressView()
                    .tint(.red)
                    .scaleEffect(4)
            }
            
        }
        .frame(width: 96, height: 96)
        .padding(.trailing)
    }
}

#Preview {
    PlayerListView(player: Roster(person: Person(id: 660271, fullName: "Shohei Ohtani", link: "/api/v1/people/660271"), position: Position(name: "Two-Way Player", abbreviation: "TWP")))
}
