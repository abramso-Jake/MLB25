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
    let jerseyImageName: String
    let logoImageName: String
}

struct TeamExtraData {
    static let infoByTeamID: [Int: TeamExtraInfo] = [
        
        // AL East
        110: TeamExtraInfo(
            description: "The Baltimore Orioles are one of the American League’s historic franchises and play at Camden Yards.",
            locationText: "Baltimore, Maryland",
            latitude: 39.2840,
            longitude: -76.6217,
            stadiumImageName: "orioles_stadium",
            jerseyImageName: "orioles_jersey",
            logoImageName: "orioles_logo"
        ),
        111: TeamExtraInfo(
            description: "The Boston Red Sox are one of baseball’s most iconic teams and play at Fenway Park.",
            locationText: "Boston, Massachusetts",
            latitude: 42.3467,
            longitude: -71.0972,
            stadiumImageName: "redsox_stadium",
            jerseyImageName: "redsox_jersey",
            logoImageName: "redsox_logo"
        ),
        147: TeamExtraInfo(
            description: "The New York Yankees are one of the most successful and recognizable franchises in baseball history.",
            locationText: "Bronx, New York",
            latitude: 40.8296,
            longitude: -73.9262,
            stadiumImageName: "yankees_stadium",
            jerseyImageName: "yankees_jersey",
            logoImageName: "yankees_logo"
        ),
        139: TeamExtraInfo(
            description: "The Tampa Bay Rays are known for innovation and consistent competitiveness in the American League East.",
            locationText: "St. Petersburg, Florida",
            latitude: 27.7682,
            longitude: -82.6534,
            stadiumImageName: "rays_stadium",
            jerseyImageName: "rays_jersey",
            logoImageName: "rays_logo"
        ),
        141: TeamExtraInfo(
            description: "The Toronto Blue Jays are Canada’s MLB team and play at Rogers Centre.",
            locationText: "Toronto, Ontario",
            latitude: 43.6414,
            longitude: -79.3894,
            stadiumImageName: "bluejays_stadium",
            jerseyImageName: "bluejays_jersey",
            logoImageName: "bluejays_logo"
        ),
        
        // AL Central
        145: TeamExtraInfo(
            description: "The Chicago White Sox are a longtime American League franchise playing on the South Side of Chicago.",
            locationText: "Chicago, Illinois",
            latitude: 41.8300,
            longitude: -87.6338,
            stadiumImageName: "whitesox_stadium",
            jerseyImageName: "whitesox_jersey",
            logoImageName: "whitesox_logo"
        ),
        114: TeamExtraInfo(
            description: "The Cleveland Guardians are the American League team from Cleveland and play at Progressive Field.",
            locationText: "Cleveland, Ohio",
            latitude: 41.4962,
            longitude: -81.6852,
            stadiumImageName: "guardians_stadium",
            jerseyImageName: "guardians_jersey",
            logoImageName: "guardians_logo"
        ),
        116: TeamExtraInfo(
            description: "The Detroit Tigers are one of baseball’s classic franchises and play at Comerica Park.",
            locationText: "Detroit, Michigan",
            latitude: 42.3390,
            longitude: -83.0485,
            stadiumImageName: "tigers_stadium",
            jerseyImageName: "tigers_jersey",
            logoImageName: "tigers_logo"
        ),
        118: TeamExtraInfo(
            description: "The Kansas City Royals won the 2015 World Series and play at Kauffman Stadium.",
            locationText: "Kansas City, Missouri",
            latitude: 39.0517,
            longitude: -94.4803,
            stadiumImageName: "royals_stadium",
            jerseyImageName: "royals_jersey",
            logoImageName: "royals_logo"
        ),
        142: TeamExtraInfo(
            description: "The Minnesota Twins are the AL club in Minneapolis–St. Paul and play at Target Field.",
            locationText: "Minneapolis, Minnesota",
            latitude: 44.9817,
            longitude: -93.2778,
            stadiumImageName: "twins_stadium",
            jerseyImageName: "twins_jersey",
            logoImageName: "twins_logo"
        ),
        
        // AL West
        117: TeamExtraInfo(
            description: "The Houston Astros are a modern powerhouse in the American League and play at Daikin Park.",
            locationText: "Houston, Texas",
            latitude: 29.7573,
            longitude: -95.3555,
            stadiumImageName: "astros_stadium",
            jerseyImageName: "astros_jersey",
            logoImageName: "astros_logo"
        ),
        108: TeamExtraInfo(
            description: "The Los Angeles Angels play in Anaheim and have featured many of baseball’s biggest stars.",
            locationText: "Anaheim, California",
            latitude: 33.8003,
            longitude: -117.8827,
            stadiumImageName: "angels_stadium",
            jerseyImageName: "angels_jersey",
            logoImageName: "angels_logo"
        ),
        133: TeamExtraInfo(
            description: "The Athletics are currently based in West Sacramento and playing at Sutter Health Park during their interim stay.",
            locationText: "West Sacramento, California",
            latitude: 38.5800,
            longitude: -121.5136,
            stadiumImageName: "athletics_stadium",
            jerseyImageName: "athletics_jersey",
            logoImageName: "athletics_logo"
        ),
        136: TeamExtraInfo(
            description: "The Seattle Mariners are the Pacific Northwest’s MLB team and play at T-Mobile Park.",
            locationText: "Seattle, Washington",
            latitude: 47.5914,
            longitude: -122.3325,
            stadiumImageName: "mariners_stadium",
            jerseyImageName: "mariners_jersey",
            logoImageName: "mariners_logo"
        ),
        140: TeamExtraInfo(
            description: "The Texas Rangers won the first World Series title in franchise history in 2023 and play at Globe Life Field.",
            locationText: "Arlington, Texas",
            latitude: 32.7473,
            longitude: -97.0847,
            stadiumImageName: "rangers_stadium",
            jerseyImageName: "rangers_jersey",
            logoImageName: "rangers_logo"
        ),
        
        // NL East
        144: TeamExtraInfo(
            description: "The Atlanta Braves are one of baseball’s oldest franchises and a perennial contender in the National League.",
            locationText: "Atlanta, Georgia",
            latitude: 33.8907,
            longitude: -84.4677,
            stadiumImageName: "braves_stadium",
            jerseyImageName: "braves_jersey",
            logoImageName: "braves_logo"
        ),
        146: TeamExtraInfo(
            description: "The Miami Marlins are South Florida’s MLB team and play at loanDepot park.",
            locationText: "Miami, Florida",
            latitude: 25.7781,
            longitude: -80.2197,
            stadiumImageName: "marlins_stadium",
            jerseyImageName: "marlins_jersey",
            logoImageName: "marlins_logo"
        ),
        121: TeamExtraInfo(
            description: "The New York Mets are New York’s National League team and play at Citi Field in Queens.",
            locationText: "Queens, New York",
            latitude: 40.7571,
            longitude: -73.8458,
            stadiumImageName: "mets_stadium",
            jerseyImageName: "mets_jersey",
            logoImageName: "mets_logo"
        ),
        143: TeamExtraInfo(
            description: "The Philadelphia Phillies are one of the National League’s flagship clubs and play at Citizens Bank Park.",
            locationText: "Philadelphia, Pennsylvania",
            latitude: 39.9061,
            longitude: -75.1665,
            stadiumImageName: "phillies_stadium",
            jerseyImageName: "phillies_jersey",
            logoImageName: "phillies_logo"
        ),
        120: TeamExtraInfo(
            description: "The Washington Nationals brought a World Series title to Washington in 2019 and play at Nationals Park.",
            locationText: "Washington, D.C.",
            latitude: 38.8730,
            longitude: -77.0074,
            stadiumImageName: "nationals_stadium",
            jerseyImageName: "nationals_jersey",
            logoImageName: "nationals_logo"
        ),
        
        // NL Central
        112: TeamExtraInfo(
            description: "The Chicago Cubs are one of the most recognizable teams in sports and play at Wrigley Field.",
            locationText: "Chicago, Illinois",
            latitude: 41.9484,
            longitude: -87.6553,
            stadiumImageName: "cubs_stadium",
            jerseyImageName: "cubs_jersey",
            logoImageName: "cubs_logo"
        ),
        113: TeamExtraInfo(
            description: "The Cincinnati Reds are baseball’s first professional franchise and play at Great American Ball Park.",
            locationText: "Cincinnati, Ohio",
            latitude: 39.0979,
            longitude: -84.5082,
            stadiumImageName: "reds_stadium",
            jerseyImageName: "reds_jersey",
            logoImageName: "reds_logo"
        ),
        158: TeamExtraInfo(
            description: "The Milwaukee Brewers are the National League club in Wisconsin and play at American Family Field.",
            locationText: "Milwaukee, Wisconsin",
            latitude: 43.0280,
            longitude: -87.9712,
            stadiumImageName: "brewers_stadium",
            jerseyImageName: "brewers_jersey",
            logoImageName: "brewers_logo"
        ),
        134: TeamExtraInfo(
            description: "The Pittsburgh Pirates are one of baseball’s traditional franchises and play at PNC Park.",
            locationText: "Pittsburgh, Pennsylvania",
            latitude: 40.4469,
            longitude: -80.0057,
            stadiumImageName: "pirates_stadium",
            jerseyImageName: "pirates_jersey",
            logoImageName: "pirates_logo"
        ),
        138: TeamExtraInfo(
            description: "The St. Louis Cardinals are one of baseball’s most successful organizations and play at Busch Stadium.",
            locationText: "St. Louis, Missouri",
            latitude: 38.6226,
            longitude: -90.1928,
            stadiumImageName: "cardinals_stadium",
            jerseyImageName: "cardinals_jersey",
            logoImageName: "cardinals_logo"
        ),
        
        // NL West
        109: TeamExtraInfo(
            description: "The Arizona Diamondbacks won the 2001 World Series and play at Chase Field in Phoenix.",
            locationText: "Phoenix, Arizona",
            latitude: 33.4453,
            longitude: -112.0667,
            stadiumImageName: "diamondbacks_stadium",
            jerseyImageName: "diamondbacks_jersey",
            logoImageName: "diamondbacks_logo"
        ),
        115: TeamExtraInfo(
            description: "The Colorado Rockies are Denver’s MLB team and play at Coors Field.",
            locationText: "Denver, Colorado",
            latitude: 39.7559,
            longitude: -104.9942,
            stadiumImageName: "rockies_stadium",
            jerseyImageName: "rockies_jersey",
            logoImageName: "rockies_logo"
        ),
        119: TeamExtraInfo(
            description: "The Los Angeles Dodgers are one of baseball’s premier franchises and play at Dodger Stadium.",
            locationText: "Los Angeles, California",
            latitude: 34.0739,
            longitude: -118.2400,
            stadiumImageName: "dodgers_stadium",
            jerseyImageName: "dodgers_jersey",
            logoImageName: "dodgers_logo"
        ),
        135: TeamExtraInfo(
            description: "The San Diego Padres are one of MLB’s most exciting recent contenders and play at Petco Park.",
            locationText: "San Diego, California",
            latitude: 32.7073,
            longitude: -117.1573,
            stadiumImageName: "padres_stadium",
            jerseyImageName: "padres_jersey",
            logoImageName: "padres_logo"
        ),
        137: TeamExtraInfo(
            description: "The San Francisco Giants are a historic National League franchise and play at Oracle Park.",
            locationText: "San Francisco, California",
            latitude: 37.7786,
            longitude: -122.3893,
            stadiumImageName: "giants_stadium",
            jerseyImageName: "giants_jersey",
            logoImageName: "giants_logo"
        )
    ]
}
