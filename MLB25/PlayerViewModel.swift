//
//  PlayerViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation

enum StatSelection: CaseIterable, Hashable {
    case season2026
    case season2025
    case career
    
    var statsValue: String {
        switch self {
        case .season2026, .season2025:
            return "season"
        case .career:
            return "career"
        }
    }
    
    var seasonValue: Int? {
        switch self {
        case .season2026:
            return 2026
        case .season2025:
            return 2025
        case .career:
            return nil
        }
    }
    
    var displayName: String {
        switch self {
        case .season2026:
            return "2026"
        case .season2025:
            return "2025"
        case .career:
            return "Career"
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
    
    
    func getData(for player: Roster, selection: StatSelection) async { //Put function on guide
        isLoading = true
        errorMessage = ""
        statLine = nil
        secondStatLine = nil
        
        let isShohei = (player.id == 660271)
        
        do{
            if isShohei{
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
    
    
}
