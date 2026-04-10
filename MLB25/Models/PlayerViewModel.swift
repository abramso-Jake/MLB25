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

@MainActor
@Observable
class PlayerViewModel{
    var statLine: PlayerStat?
    var secondStatLine: PlayerStat?
    var isLoading = false
    var errorMessage = ""
    var availableSeasons: [String] = []
    
    
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
    
}
