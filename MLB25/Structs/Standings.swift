//
//  Standings.swift
//  MLB25
//
//  Created by Jake Abramson on 4/8/26.
//

import Foundation

struct StandingsArray: Codable {
    let records: [StandingsRecord]
}

struct StandingsRecord: Codable {
    let teamRecords: [TeamRecord]
}

struct TeamRecord: Codable {
    let team: TeamSummary
    let leagueRecord: LeagueRecord
}

struct TeamSummary: Codable {
    let id: Int
    let name: String
}

struct LeagueRecord: Codable {
    let wins: Int
    let losses: Int
    let pct: String?
}
