//
//  Search.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import Foundation

struct SearchArray: Codable {
    let people: [SearchPlayer]
}

struct SearchPlayer: Codable, Identifiable, Hashable{
    let id: Int
    let fullName: String
    let link: String
    let primaryPosition: SearchPosition?
    
    var positionName: String {
            primaryPosition?.name ?? "Unknown"
        }
        
    var positionAbbreviation: String {
        primaryPosition?.abbreviation ?? ""
    }
}

struct SearchPosition: Codable, Hashable {
    let name: String
    let abbreviation: String
}
