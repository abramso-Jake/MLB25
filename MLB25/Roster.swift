//
//  Roster.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation

struct RosterArray: Codable {
    let roster: [Roster]
}

struct Roster: Codable, Identifiable {
    let person: Person
    let position: Position
    
    var id: Int { person.id }
    var fullName: String { person.fullName }
    var link: String { person.link }
    var positionName: String { position.name }
    var positionAbbreviation: String { position.abbreviation }
}
extension Roster {
    var headshotURL: URL? {
        URL(string: "https://img.mlbstatic.com/mlb-photos/image/upload/w_213,q_auto:best/v1/people/\(id)/headshot/67/current")
    }
}

struct Person: Codable {
    let id: Int
    let fullName: String
    let link: String
}

struct Position: Codable {
    let name: String
    let abbreviation: String
}
