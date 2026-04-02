//
//  Team.swift
//  MLB25
//
//  Created by Jake Abramson on 4/1/26.
//

import Foundation

struct Team: Codable, Identifiable {
    let id: Int
    let name: String
    let link: String
    
    enum CodingKeys: CodingKey {
        case id, name, link
    }
}

struct TeamsArray: Codable {
    let teams: [Team]
}

