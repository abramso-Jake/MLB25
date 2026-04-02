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
    var isLoading = false
    var errorMessage = ""
    
    
    func getData(for player: Roster, selection: StatSelection) async { //Put function on guide
        isLoading = true
        errorMessage = ""
        statLine = nil
        let group = player.positionAbbreviation == "P" ? "pitching" : "hitting"
        
        
        var urlString = "https://statsapi.mlb.com/api/v1/people/\(player.id)/stats?stats=\(selection.statsValue)&group=\(group)"
            
        if let season = selection.seasonValue {
            urlString += "&season=\(season)"
        }
        
        print("We are accessing the URL \(urlString)") //Need URL object
        guard let url = URL(string: urlString) else {
            print("ERROR: could not create a url from the string")
            isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            do {
                let response = try JSONDecoder().decode(PlayerStatsArray.self, from: data)
                self.statLine = response.stats.first?.splits.first?.stat
                if self.statLine == nil {
                    errorMessage = "No Stats Available"
                }
            } catch {
                print("JSON Error: \(error)")
                errorMessage = "JSON Decoding error"
                isLoading = false
                return
            }
            isLoading = false
        } catch{
            errorMessage = "Error loading player stats."
            print("ERROR: \(error.localizedDescription)")
            isLoading = false
        }
       
        
    }
}


