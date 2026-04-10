//
//  TeamViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation
@MainActor
@Observable

class TeamViewModel{
    var teams: [Team] = []
    let urlString = "https://statsapi.mlb.com/api/v1/teams?sportId=1"
    var isLoading = false
    var recordsByTeamID: [Int: String] = [:]
    
    func getData() async { //Put function on guide
        isLoading = true
        print("We are accessing the URL \(urlString)") //Need URL object
        guard let url = URL(string: urlString) else {
            print("ERROR: could not create a url from the string")
            isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let response = try? JSONDecoder().decode(TeamsArray.self, from: data) else {
                print("JSON Error: Could not decode JSON from url \(urlString)") //mismatch between your struct and api's key-value pairs
                isLoading = false
                return
            }
            print("JSON returned! # of teams: \(teams.count)")
            self.teams = response.teams
            isLoading = false
        } catch{
            print("ERROR")
            isLoading = false
        }
        
    }
    func returnIndex(of team: Team)-> Int{
        guard let index = teams.firstIndex(where: {$0.id == team.id}) else {return 0}
        return index + 1
    }
    func getRecords(for season: Int = 2026) async {
        let urlString = "https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=\(season)&standingsTypes=regularSeason"

        guard let url = URL(string: urlString) else {
            print("ERROR: bad standings URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(StandingsArray.self, from: data)

            var temp: [Int: String] = [:]

            for recordGroup in response.records {
                for teamRecord in recordGroup.teamRecords {
                    let wins = teamRecord.leagueRecord.wins
                    let losses = teamRecord.leagueRecord.losses
                    temp[teamRecord.team.id] = "\(wins)-\(losses)"
                }
            }

            self.recordsByTeamID = temp
        } catch {
            print("ERROR loading records: \(error.localizedDescription)")
        }
    }
   
}
