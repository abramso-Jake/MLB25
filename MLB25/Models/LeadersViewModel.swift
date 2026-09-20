//
//  LeadersViewModel.swift
//  MLB25
//
//  Created by Jake Abramson on 4/8/26.
//

import Foundation

enum PlayerPoolFilter: String, CaseIterable {
    case all = "All"
    case rookies = "Rookies"
}

@MainActor
@Observable
class LeadersViewModel {
    var selectedGroup: LeaderGroup = .hitting
    var selectedSeason: String = "2026"
    var isLoading = false
    var errorMessage = ""
    var rookiesOnly: Bool = false
    var poolFilter: PlayerPoolFilter = .all
    
    var hittingLeaders: [HittingLeaderCategory: [LeaderEntry]] = [:]
    var pitchingLeaders: [PitchingLeaderCategory: [LeaderEntry]] = [:]

    func loadLeaders() async {
        isLoading = true
        errorMessage = ""

        do {
            switch selectedGroup {
            case .hitting:
                var temp: [HittingLeaderCategory: [LeaderEntry]] = [:]

                for category in HittingLeaderCategory.allCases {
                    let pool: String

                    if poolFilter == .rookies {
                        switch category {
                        case .onBasePlusSlugging, .avg, .onBasePercentage:
                            pool = "qualified_rookies"
                        default:
                            pool = "rookies"
                        }
                    } else {
                        switch category {
                        case .onBasePlusSlugging, .avg, .onBasePercentage:
                            pool = "qualified"
                        default:
                            pool = "all"
                        }
                    }
                    temp[category] = try await fetchLeaders(
                        category: category.rawValue,
                        statGroup: "hitting",
                        season: selectedSeason,
                        limit: 5,
                        playerPool: pool
                    )
                }
                isLoading = false
                hittingLeaders = temp

            case .pitching:
                var temp: [PitchingLeaderCategory: [LeaderEntry]] = [:]

                for category in PitchingLeaderCategory.allCases {
                    let pool: String

                    if poolFilter == .rookies {
                        switch category {
                        case .earnedRunAverage, .whip:
                            pool = "qualified_rookies"
                        case .wins, .strikeOuts, .saves:
                            pool = "rookies"
                        }
                    } else {
                        switch category {
                        case .earnedRunAverage, .whip:
                            pool = "qualified"
                        case .wins, .strikeOuts, .saves:
                            pool = "all"
                        }
                    }
                    
                    temp[category] = try await fetchLeaders(
                        category: category.rawValue,
                        statGroup: "pitching",
                        season: selectedSeason,
                        limit: 5,
                        playerPool: pool
                    )
                }
                isLoading = false
                pitchingLeaders = temp
            }
        } catch {
            errorMessage = "Could not load leaders."
            print("LEADERS ERROR: \(error.localizedDescription)")
            isLoading = false
        }

        isLoading = false
    }

    private func fetchLeaders(category: String, statGroup: String, season: String, limit: Int, playerPool: String) async throws -> [LeaderEntry]{
        let urlString = "https://statsapi.mlb.com/api/v1/stats/leaders?leaderCategories=\(category)&season=\(season)&statGroup=\(statGroup)&limit=\(limit)&playerPool=\(playerPool)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(LeadersArray.self, from: data)

        return response.leagueLeaders.first?.leaders ?? []
    }
}
