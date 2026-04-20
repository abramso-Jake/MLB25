//
//  PlayerViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation

enum PlayerEntry {
    case roster
    case search
}

enum PlayerStatSelection: Hashable {
    case career
    case season(String)
    
    var displayName: String {
        switch self{
        case .career:
            return "Career"
        case .season(let year):
            return year
        }
    }
    var statsValue: String {
        switch self {
        case .career:
            return "career"
        case .season:
            return "season"
        }
    }
    var seasonValue: String? {
        switch self {
        case .career:
            return nil
        case .season(let year):
            return year
        }
    }
}

enum HitterSplitSelection: String, CaseIterable, Identifiable {
    case overall = "Overall"
    case vsLeftPitcher = "vs LHP"
    case vsRightPitcher = "vs RHP"

    var id: String { rawValue }

    var sitCode: String? {
        switch self {
        case .overall:
            return nil
        case .vsLeftPitcher:
            return "vl"
        case .vsRightPitcher:
            return "vr"
        }
    }
}

enum PitcherSplitSelection: String, CaseIterable, Identifiable {
    case overall = "Overall"
    case vsLeftBatter = "vs LHB"
    case vsRightBatter = "vs RHB"

    var id: String { rawValue }

    var sitCode: String? {
        switch self {
        case .overall:
            return nil
        case .vsLeftBatter:
            return "vl"
        case .vsRightBatter:
            return "vr"
        }
    }
}

@MainActor
@Observable
class PlayerViewModel{
    var statLine: PlayerStat?
    var secondStatLine: PlayerStat?
    var isLoading = false
    var errorMessage = ""
    var availableSeasons: [String] = []
    var playerDetails: PlayerDetails?
    var yearByYear: [YearByYearSplit] = []
    var hitterSplitStats: [SplitStatSplit] = []
    var pitcherSplitStats: [SplitStatSplit] = []
    var awards: [PlayerAward] = []

    let majorAwardKeywords = [
        "MVP",
        "Silver Slugger",
        "All-Star",
        "Cy Young",
        "Rookie of the Year",
        "Gold Glove",
        "World Series Championship",
        "NLCS MVP",
        "ALCS MVP"
    ]
    var majorAwards: [PlayerAward] {
        awards.filter { award in
            guard let name = award.name else { return false }
            return majorAwardKeywords.contains { name.localizedCaseInsensitiveContains($0) }
        }
        .sorted { ($0.season ?? "") > ($1.season ?? "") }
    }
    func awardCount(for awardName: String) -> Int {
        majorAwards.filter { $0.name == awardName }.count
    }
    
    func awards(for season: String) -> [PlayerAward] {
        majorAwards
            .filter { $0.season == season }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    func getAwards(for player: Roster) async {
        let urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/awards"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AwardsResponse.self, from: data)
            self.awards = response.awards
        } catch {
            print("ERROR loading awards: \(error.localizedDescription)")
        }
    }
    
    func getHitterSplitStats(for player: Roster, season: String, sitCode: String?) async {
        if sitCode == nil {
            await getData(for: player, selection: .season(season))
            return
        }

        isLoading = true
        errorMessage = ""
        statLine = nil

        let urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=statSplits&group=hitting&sitCodes=\(sitCode!)&season=\(season)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Bad URL"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SplitStatsArray.self, from: data)

            statLine = response.stats.first?.splits.first?.stat

            if statLine == nil {
                errorMessage = "No Stats Available"
            }
        } catch {
            errorMessage = "Error loading split stats."
            print("ERROR loading hitter split stats: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func getPitcherSplitStats(for player: Roster, season: String, sitCode: String?) async {
        if sitCode == nil {
            await getData(for: player, selection: .season(season))
            return
        }

        isLoading = true
        errorMessage = ""
        statLine = nil

        let urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=statSplits&group=pitching&sitCodes=\(sitCode!)&season=\(season)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Bad URL"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SplitStatsArray.self, from: data)

            statLine = response.stats.first?.splits.first?.stat

            if statLine == nil {
                errorMessage = "No Stats Available"
            }
        } catch {
            errorMessage = "Error loading split stats."
            print("ERROR loading pitcher split stats: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func getTwoWayPitcherSplitStats(for player: Roster, season: String, sitCode: String?) async {
        if sitCode == nil {
            await getData(for: player, selection: .season(season))
            return
        }

        isLoading = true
        errorMessage = ""
        secondStatLine = nil

        let urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=statSplits&group=pitching&sitCodes=\(sitCode!)&season=\(season)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Bad URL"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SplitStatsArray.self, from: data)

            secondStatLine = response.stats.first?.splits.first?.stat

            if secondStatLine == nil {
                errorMessage = "No Pitching Split Stats Available"
            }
        } catch {
            errorMessage = "Error loading pitching split stats."
            print("ERROR loading two-way pitching split stats: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func getData(for player: Roster, selection: PlayerStatSelection) async { //Put function on guide
        isLoading = true
        errorMessage = ""
        statLine = nil
        secondStatLine = nil
        
        let exception = (player.id == 660271 || player.id == 121578)
        
        do{
            if exception{
                var hittingURL = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=\(selection.statsValue)&group=hitting"
                var pitchingURL = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=\(selection.statsValue)&group=pitching"
                
                if let season = selection.seasonValue{
                    hittingURL += "&season=\(season)"
                    pitchingURL += "&season=\(season)"
                }
                
                guard let hittingURLObj = URL(string: hittingURL), let pitchingURLObj = URL(string: pitchingURL) else {
                    errorMessage = "Bad URL"
                    isLoading = false
                    return
                }
                let (hittingData, _) = try await URLSession.shared.data(from: hittingURLObj)
                let (pitchingData, _) = try await URLSession.shared.data(from: pitchingURLObj)
                
                let hittingResponse = try JSONDecoder().decode(PlayerStatsArray.self, from: hittingData)
                let pitchingResponse = try JSONDecoder().decode(PlayerStatsArray.self, from: pitchingData)
                
                self.statLine = hittingResponse.stats.first?.splits.first?.stat
                self.secondStatLine = pitchingResponse.stats.first?.splits.first?.stat
                
                if self.statLine == nil && self.secondStatLine == nil {
                    errorMessage = "No Stats Available"
                }
            } else {
                let group = player.positionAbbreviation == "P" ? "pitching" : "hitting"
                
                var urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=\(selection.statsValue)&group=\(group)"
                
                if let season = selection.seasonValue {
                    urlString += "&season=\(season)"
                }
                
                guard let url = URL(string: urlString) else {
                    errorMessage = "Bad URL"
                    isLoading = false
                    return
                }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(PlayerStatsArray.self, from: data)
                
                self.statLine = response.stats.first?.splits.first?.stat
                
                if self.statLine == nil {
                    errorMessage = "No Stats Available"
                }
            }
        } catch{
            errorMessage = "Error loading player stats."
            print("ERROR: \(error.localizedDescription)")
        }
        isLoading = false
        
        //        let group = player.positionAbbreviation == "P" ? "pitching" : "hitting"
        //
        //        var urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=\(selection.statsValue)&group=\(group)"
        //
        //        if let season = selection.seasonValue {
        //            urlString += "&season=\(season)"
        //        }
        //
        //        print("We are accessing the URL \(urlString)") //Need URL object
        //        guard let url = URL(string: urlString) else {
        //            print("ERROR: could not create a url from the string")
        //            isLoading = false
        //            return
        //        }
        //        do {
        //            let (data, _) = try await URLSession.shared.data(from: url)
        //            do {
        //                let response = try JSONDecoder().decode(PlayerStatsArray.self, from: data)
        //                self.statLine = response.stats.first?.splits.first?.stat
        //                if self.statLine == nil {
        //                    errorMessage = "No Stats Available"
        //                }
        //            } catch {
        //                print("JSON Error: \(error)")
        //                errorMessage = "JSON Decoding error"
        //                isLoading = false
        //                return
        //            }
        //            isLoading = false
        //        } catch{
        //            errorMessage = "Error loading player stats."
        //            print("ERROR: \(error.localizedDescription)")
        //            isLoading = false
        //        }
        //
        //
        //    }
        
    }
    
    func getAvailableSeasons(playerId: Int, position: String) async {
        let group = position == "P" ? "pitching" : "hitting"
        let urlString = "https://statsapi.mlb.com/api/v1/people/\(playerId)/stats?stats=yearByYear&group=\(group)"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YearByYearArray.self, from: data)
            let seasons = response.stats.first?.splits.compactMap { $0.season } ?? []
            self.availableSeasons = Array(Set(seasons)).sorted(by: >)
            self.yearByYear = response.stats.first?.splits ?? []
        } catch {
            print("ERROR loading available seasons: \(error.localizedDescription)")
        }
    }
    
    func defaultSelection( for player: Roster, entryMode: PlayerEntry) -> PlayerStatSelection {
        switch entryMode {
        case .roster:
            if availableSeasons.contains("2026") {
                return .season("2026")
            } else if let mostRecent = availableSeasons.sorted(by: >).first {
                return .season(mostRecent)
            } else {
                return .career
            }

        case .search:
            return .career
        }
    }
    
    func getPlayerDetails(for player: Roster) async {
        let urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PlayerDetailsArray.self, from: data)
            self.playerDetails = response.people.first
            print("STATUS RAW:", response.people.first?.status as Any)
            print("STATUS DESC:", response.people.first?.status?.description as Any)
        } catch {
            print("ERROR loading player details: \(error.localizedDescription)")
        }
    }
    
    func teamName(for season: String) -> String? {
        let teams = yearByYear
            .filter { $0.season == season }
            .compactMap { $0.team?.name }
        
        if teams.isEmpty { return nil }
        
        // Remove duplicates
        let uniqueTeams = Array(Set(teams))
        
        // Format names (Red Sox, Blue Jays, Dodgers, etc.)
        let formattedTeams = uniqueTeams.map { fullName -> String in
            let words = fullName.components(separatedBy: " ")
            
            if words.count >= 3 {
                return words.suffix(2).joined(separator: " ")
            } else {
                return words.last ?? fullName
            }
        }
        
        return formattedTeams.joined(separator: ", ")
    }
    
    
    
}
