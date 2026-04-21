//
//  Player.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation

struct PlayerStatsArray: Codable {
    let stats: [StatsContainer]
}

struct StatsContainer: Codable {
    let splits: [StatSplit]
}

struct StatSplit: Codable {
    let season: String?
    let stat: PlayerStat
}

struct PlayerStat: Codable {
    // Hitting
    let avg: String?
    let homeRuns: Int?
    let rbi: Int?
    let obp: String?
    let slg: String?
    let ops: String?
    let hits: Int?
    let stolenBases: Int?
    let baseOnBalls: Int?
    let atBats: Int?
    
    
    // Pitching
    let shutouts: Int?
    let saves: Int?
    let gamesPlayed: Int?
    let inningsPitched: String?
    let era: String?
    let wins: Int?
    let losses: Int?
    let strikeOuts: Int?
    let whip: String?
    let completeGames: Int?
    let pickoffs: Int?
    let earnedRuns: Int?
    let winPercentage: String?
}

struct YearByYearArray: Codable {
    let stats: [YearByYear]
}

struct YearByYear: Codable {
    let splits: [YearByYearSplit]
}

struct YearByYearSplit: Codable {
    let season: String?
    let team: YearByYearTeam?
}
    
struct YearByYearTeam: Codable {
    let id: Int?
    let name: String?
}

struct PlayerDetailsArray: Codable {
    let people: [PlayerDetails]
}

struct PlayerDetails: Codable {
    let id: Int
    let fullName: String
    let currentAge: Int?
    let active: Bool?
    let batSide: HandSide?
    let pitchHand: HandSide?
    let status: PlayerStatus?
}

struct HandSide: Codable {
    let code: String?
    let description: String?
}

struct PlayerStatus: Codable {
    let code: String?
    let description: String?
}

struct SplitStatsArray: Codable {
    let stats: [SplitStatsContainer]
}

struct SplitStatsContainer: Codable {
    let splits: [SplitStatSplit]
}

struct SplitStatSplit: Codable {
    let split: SplitType
    let stat: PlayerStat
}

struct SplitType: Codable {
    let code: String
    let description: String
}

struct AwardsResponse: Codable {
    let awards: [PlayerAward]
}

struct PlayerAward: Codable, Identifiable {
    let id: String
    let name: String?
    let date: String?
    let season: String?
    let team: AwardTeam?
    let player: AwardPlayer?
}

struct AwardTeam: Codable {
    let id: Int?
    let link: String?
    let teamName: String?
}

struct AwardPlayer: Codable {
    let id: Int?
    let link: String?
    let primaryPosition: AwardPosition?
}

struct AwardPosition: Codable {
    let code: String?
    let name: String?
    let type: String?
    let abbreviation: String?
}

struct DisplayAward: Identifiable, Hashable {
    let id: String
    let season: String
    let name: String
}
