//
//  PlayerListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import SwiftUI

struct PlayerListView: View {
    let player: Roster
    let entry: PlayerEntry
    
    private var isPitcherOnly: Bool {
        player.positionAbbreviation == "P"
    }
    
    private var isTwoWay: Bool {
        player.positionAbbreviation == "TWP"
    }
    
    private var isHitterOnly: Bool {
        !isPitcherOnly && !isTwoWay
    }
    
    @State private var selectedHitterSplit: HitterSplitSelection = .overall
    @State private var selectedPitcherSplit: PitcherSplitSelection = .overall
    @State private var playerVM = PlayerViewModel()
    @State private var selectedStat: PlayerStatSelection = .career
    var body: some View {
        NavigationStack{
            VStack{
                HStack {
                    Picker("Stats", selection: $selectedStat) {
                        Text("Career").tag(PlayerStatSelection.career)
                        
                        ForEach(playerVM.availableSeasons, id: \.self) { season in
                            Text(season).tag(PlayerStatSelection.season(season))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedStat) {
                        if case .career = selectedStat {
                            selectedHitterSplit = .overall
                            selectedPitcherSplit = .overall
                        }
                        
                        Task {
                            await playerVM.getData(for: player, selection: selectedStat)
                        }
                    }
                    
                    if case .season = selectedStat {
                        if isPitcherOnly {
                            Picker("Split", selection: $selectedPitcherSplit) {
                                ForEach(PitcherSplitSelection.allCases) { split in
                                    Text(split.rawValue).tag(split)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedPitcherSplit) {
                                if case let .season(season) = selectedStat {
                                    Task {
                                        await playerVM.getPitcherSplitStats(
                                            for: player,
                                            season: season,
                                            sitCode: selectedPitcherSplit.sitCode
                                        )
                                    }
                                }
                            }
                        } else if isHitterOnly {
                            Picker("Split", selection: $selectedHitterSplit) {
                                ForEach(HitterSplitSelection.allCases) { split in
                                    Text(split.rawValue).tag(split)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedHitterSplit) {
                                if case let .season(season) = selectedStat {
                                    Task {
                                        await playerVM.getHitterSplitStats(
                                            for: player,
                                            season: season,
                                            sitCode: selectedHitterSplit.sitCode
                                        )
                                    }
                                }
                            }
                        } else if isTwoWay, case .season = selectedStat {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Hitting Split", selection: $selectedHitterSplit) {
                                    ForEach(HitterSplitSelection.allCases) { split in
                                        Text(split.rawValue).tag(split)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: selectedHitterSplit) {
                                    if case let .season(season) = selectedStat {
                                        Task {
                                            await playerVM.getHitterSplitStats(
                                                for: player,
                                                season: season,
                                                sitCode: selectedHitterSplit.sitCode
                                            )
                                        }
                                    }
                                }

                                Picker("Pitching Split", selection: $selectedPitcherSplit) {
                                    ForEach(PitcherSplitSelection.allCases) { split in
                                        Text(split.rawValue).tag(split)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: selectedPitcherSplit) {
                                    if case let .season(season) = selectedStat {
                                        Task {
                                            await playerVM.getTwoWayPitcherSplitStats(
                                                for: player,
                                                season: season,
                                                sitCode: selectedPitcherSplit.sitCode
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer()
                HStack{
                    VStack(alignment: .leading, spacing: 6) {
                        if let details = playerVM.playerDetails {
                            if case let .season(season) = selectedStat,
                               let teamName = playerVM.teamName(for: season) {
                                Text("Team: \(teamName)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                            if let active = details.active {
                                Text(active ? "Status: Active" : "Status: Inactive")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                            if details.active == true, let age = details.currentAge {
                                Text("Age: \(age)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            if let throwHand = details.pitchHand?.description {
                                Text("Throws: \(throwHand)")
                                    .font(.subheadline)
                            }
                            if let batSide = details.batSide?.description {
                                Text("Bats: \(batSide)")
                                    .font(.subheadline)
                            }
                        }
                        
                        PlayerImage
                            .padding(.vertical)
                            .offset(y: 20)
                        if case .career = selectedStat, !playerVM.careerAwardTallies.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Awards")
                                    .font(.title3)
                                    .fontWeight(.bold)

                                ForEach(playerVM.careerAwardTallies, id: \.name) { award in
                                    Text("\(award.count)x \(award.name)")
                                        .font(.subheadline)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.top, 10)
                            .padding()
                            .padding(.horizontal, 5)
                            .offset(x: -20)
                        }
                        if case let .season(season) = selectedStat {
                            let seasonAwards = playerVM.awards(for: season)

                            if !seasonAwards.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Awards")
                                        .font(.title3)
                                        .fontWeight(.bold)

                                    ForEach(seasonAwards) { award in
                                        Text(award.name)
                                            .font(.subheadline)
                                            .minimumScaleFactor(0.5)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.top, 10)
                                .padding()
                                .padding(.horizontal, 5)
                                .offset(x: -20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    if playerVM.isLoading{
                        ProgressView()
                            .tint(.red)
                            .scaleEffect(4)
                    } else if let stat = playerVM.statLine {
                        if player.positionAbbreviation == "P"{
                            VStack(alignment: .leading){
                                if selectedPitcherSplit == .overall {
                                    Text("Games Played: \(stat.gamesPlayed ?? 0)")
                                    Text("IP: \(stat.inningsPitched ?? "-")")
                                    Text("ERA: \(stat.era ?? "-")")
                                    Text("WHIP: \(stat.whip ?? "-")")
                                    Text("ER: \(stat.earnedRuns ?? 0)")
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
                                }else {
                                    Text("At Bats: \(stat.atBats ?? 0)")
                                    Text("OBA: \(stat.avg ?? "-")")
                                    Text("WHIP: \(stat.whip ?? "-")")
                                    Text("Walks: \(stat.baseOnBalls ?? 0)")
                                    Text("Hits: \(stat.hits ?? 0)")
                                    Text("SO: \(stat.strikeOuts ?? 0)")
                                }
                            }
                            .font(.title)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        } else if (player.positionAbbreviation == "TWP" || player.fullName == "Babe Ruth"){
                            VStack(alignment: .leading){
                                if let pitching = playerVM.secondStatLine {
                                    Text("Pitching:")
                                        .font(.title3)
                                        .fontWeight(.black)
                                    if selectedPitcherSplit == .overall{
                                        Text("Games Played: \(pitching.gamesPlayed ?? 0)")
                                        Text("IP: \(pitching.inningsPitched ?? "-")")
                                        Text("ERA: \(pitching.era ?? "-")")
                                        Text("WHIP: \(pitching.whip ?? "-")")
                                        Text("ER: \(pitching.earnedRuns ?? 0)")
                                        Text("W: \(pitching.wins ?? 0)")
                                        Text("L: \(pitching.losses ?? 0)")
                                        Text("SO: \(pitching.strikeOuts ?? 0)")
                                        Text("OBA: \(pitching.avg ?? "-")")
                                        Text("Walks: \(pitching.baseOnBalls ?? 0)")
                                        let cg = (pitching.completeGames ?? 0)
                                        if cg >= 1{
                                            Text("CG: \(cg)")
                                        }
                                        let sho = (pitching.shutouts ?? 0)
                                        if sho >= 1{
                                            Text("SHO: \(sho)")
                                        }
                                    } else {
                                        Text("At Bats: \(pitching.atBats ?? 0)")
                                        Text("OBA: \(pitching.avg ?? "-")")
                                        Text("WHIP: \(pitching.whip ?? "-")")
                                        Text("Walks: \(pitching.baseOnBalls ?? 0)")
                                        Text("Hits: \(pitching.hits ?? 0)")
                                        Text("SO: \(pitching.strikeOuts ?? 0)")
                                    }
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
                                    Text("OBP: \(stat.obp ?? "-")")
                                    Text("HR: \(hitting.homeRuns ?? 0)")
                                    Text("RBI: \(hitting.rbi ?? 0)")
                                    Text("OPS: \(hitting.ops ?? "-")")
                                    Text("SO: \(hitting.strikeOuts ?? 0)")
                                }
                            }
                        } else{
                            VStack(alignment: .leading) {
                                Text("At Bats: \(stat.atBats ?? 0)")
                                Text("Walks: \(stat.baseOnBalls ?? 0)")
                                Text("Hits: \(stat.hits ?? 0)")
                                let sb = (stat.stolenBases ?? 0)
                                if sb >= 20{
                                    Text("Stolen Bases: \(stat.stolenBases ?? 0)")
                                }
                                Text("AVG: \(stat.avg ?? "-")")
                                Text("OBP: \(stat.obp ?? "-")")
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
                await playerVM.getAwards(for: player)
                await playerVM.getPlayerDetails(for: player)
                await playerVM.getAvailableSeasons(
                    playerId: player.id,
                    position: player.positionAbbreviation
                )
                selectedStat = playerVM.defaultSelection(for: player, entryMode: entry)
                await playerVM.getData(for: player, selection: selectedStat)
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
                    .frame(width: 100, height: 150)
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
    PlayerListView(player: Roster(person: Person(id: 660271, fullName: "Shohei Ohtani", link: "/api/v1/people/660271"), position: Position(name: "Two-Way Player", abbreviation: "TWP")), entry: .roster)
}
