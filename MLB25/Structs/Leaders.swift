//
//  Leaders.swift
//  MLB25
//
//  Created by Jake Abramson on 4/8/26.
//

import Foundation

enum LeaderGroup: String, CaseIterable, Identifiable {
    case hitting
    case pitching

    var id: String { rawValue }
}

enum HittingLeaderCategory: String, CaseIterable, Identifiable {
    case homeRuns
    case hits
    case rbi
    case avg
    case onBasePlusSlugging
    case stolenBases

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeRuns: return "Home Runs"
        case .hits: return "Hits"
        case .rbi: return "RBIs"
        case .stolenBases: return "Stolen Bases"
        case .onBasePlusSlugging: return "OPS"
        case .avg: return "AVG"
        }
    }
}

enum PitchingLeaderCategory: String, CaseIterable, Identifiable {
    case wins
    case earnedRunAverage
    case saves
    case strikeOuts
    case whip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wins: return "Wins"
        case .strikeOuts: return "Strikeouts"
        case .saves: return "Saves"
        case .whip: return "WHIP"
        case .earnedRunAverage: return "ERA"
        }
    }
}

struct LeadersArray: Codable {
    let leagueLeaders: [LeaderCategory]
}

struct LeaderCategory: Codable {
    let leaderCategory: String
    let leaders: [LeaderEntry]
}

struct LeaderEntry: Codable, Identifiable {
    let rank: Int
    let value: String
    let person: LeaderPerson?
    let team: LeaderTeam?

    var id: String {
        "\(person?.id ?? 0)-\(rank)-\(value)"
    }
}

struct LeaderPerson: Codable {
    let id: Int
    let fullName: String
    let link: String?
}

struct LeaderTeam: Codable {
    let id: Int?
    let name: String?
    let link: String?
}
