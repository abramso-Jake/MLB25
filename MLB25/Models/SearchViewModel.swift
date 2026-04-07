//
//  SearchViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import Foundation

@MainActor
@Observable

class SearchViewModel{
    var searchText = ""
    var results: [SearchPlayer] = []
    var isLoading = false
    var errorMessage = ""
    
    func searchPlayers() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = ""
        
        let encodedName = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://statsapi.mlb.com/api/v1/people/search?names=\(encodedName)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Bad URL"
            isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SearchArray.self, from: data)
            self.results = response.people
            isLoading = false
        } catch {
            errorMessage = "Could not load players."
            print("SEARCH ERROR: \(error)")
            isLoading = false
        }
        isLoading = false
        
    }
}
