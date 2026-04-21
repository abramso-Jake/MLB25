import Foundation
import CoreLocation

struct TeamDetailResponse: Decodable {
    let teams: [TeamDetail]
}

struct TeamDetail: Decodable, Identifiable {
    let id: Int
    let name: String
    let teamName: String?
    let locationName: String?
    let franchiseName: String?
    let clubName: String?
    let abbreviation: String?
    let firstYearOfPlay: String?
    let venue: TeamVenueReference?
    let division: NamedReference?
}

struct TeamVenueReference: Decodable {
    let id: Int
    let name: String
}

struct NamedReference: Decodable {
    let id: Int
    let name: String
}

struct VenueResponse: Decodable {
    let venues: [VenueSummary]
}

struct VenueSummary: Decodable, Identifiable {
    let id: Int
    let name: String
}

struct TeamExtraInfo {
    let description: String
    let locationText: String
    let latitude: Double
    let longitude: Double
    let stadiumImageName: String
    let homeJerseyImageName: String
    let awayJerseyImageName: String
    let logoImageName: String
}

struct TeamExtraData {
    static let infoByTeamID: [Int: TeamExtraInfo] = [
        147: TeamExtraInfo(
            description: "The Yankees are one of the most storied franchises in baseball history.",
            locationText: "Bronx, New York",
            latitude: 40.8296,
            longitude: -73.9262,
            stadiumImageName: "yankees_stadium",
            homeJerseyImageName: "yankees_home",
            awayJerseyImageName: "yankees_away",
            logoImageName: "yankees_logo"
        )
    ]
}
