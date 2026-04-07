//
//  RosterViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation
@MainActor
@Observable

class RosterViewModel{
    var roster: [Roster] = []
    var isLoading = false
    func getData(for team: Team) async { //Put function on guide
        isLoading = true
        let urlString = "https://statsapi.mlb.com/api/v1/teams/\(team.id)/roster"
        
        print("We are accessing the URL \(urlString)") //Need URL object
        guard let url = URL(string: urlString) else {
            print("ERROR: could not create a url from the string")
            isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let response = try? JSONDecoder().decode(RosterArray.self, from: data) else {
                print("JSON Error: Could not decode JSON from url \(urlString)") //mismatch between your struct and api's key-value pairs
                isLoading = false
                return
            }
            print("JSON returned! # of teams: \(response.roster.count)")
            self.roster = response.roster
            isLoading = false
            
        } catch{
            isLoading = false
            print("ERROR")
        }
        
    }
    func returnIndex(of r: Roster)-> Int{
        guard let index = roster.firstIndex(where: {$0.id == r.id}) else {return 0}
        return index + 1
    }
    
}
   
