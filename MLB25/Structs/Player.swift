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
}

struct YearByYearArray: Codable {
    let stats: [YearByYear]
}

struct YearByYear: Codable {
    let splits: [YearByYearSplit]
}

struct YearByYearSplit: Codable {
    let season: String?
}
