import SwiftUI
import MapKit

struct TeamDetailListView: View {
    let team: Team
    let record: String
    @State private var detailVM = TeamDetailViewModel()
    @State private var teamVM = TeamViewModel()
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if let teamDetail = detailVM.teamDetail,
                       let extra = detailVM.extraInfo {
                        
                        VStack(alignment: .center, spacing: 12) {
                            Image(extra.logoImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)

                            Text(teamDetail.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, alignment: .center)

                            if let locationName = teamDetail.locationName {
                                Text(locationName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        GroupBox("Team Information") {
                            VStack(alignment: .leading, spacing: 10) {
                                detailRow(title: "Franchise", value: teamDetail.franchiseName ?? "N/A")
                                detailRow(title: "Club Name", value: teamDetail.clubName ?? "N/A")
                                detailRow(title: "Abbreviation", value: teamDetail.abbreviation ?? "N/A")
                                detailRow(title: "First Year of Play", value: teamDetail.firstYearOfPlay ?? "N/A")
                                detailRow(title: "Division", value: teamDetail.division?.name ?? "N/A")
                                detailRow(title: "Venue", value: teamDetail.venue?.name ?? "N/A")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        GroupBox("Description") {
                            Text(extra.description)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        
                        GroupBox("Location") {
                            VStack(alignment: .leading, spacing: 10) {
                                detailRow(title: "Location", value: extra.locationText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        
                        let stadiumCoordinate = CLLocationCoordinate2D(
                            latitude: extra.latitude,
                            longitude: extra.longitude
                        )
                        
                        Map {
                            Marker(
                                teamDetail.venue?.name ?? team.name,
                                coordinate: stadiumCoordinate
                            )
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        GroupBox("Stadium") {
                            Image(extra.stadiumImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .frame(maxWidth: .infinity)
                        
                        GroupBox("Jersey") {
                            Image(extra.jerseyImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                        }
                        .frame(maxWidth: .infinity)
                        
                        NavigationLink {
                            RosterListView(
                                team: team,
                                record: record // or "--" if not passed yet
                            )
                        } label: {
                            Text("Rosters")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 10)
                    }
                    
                    if !detailVM.errorMessage.isEmpty {
                        Text(detailVM.errorMessage)
                            .foregroundStyle(.red)
                            .font(.headline)
                    }
                }
                .padding()
            }
            .padding(10)
            
            if detailVM.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.blue)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await detailVM.getData(for: team)
        }
    }
    
    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    TeamDetailListView(
        team: Team(
            id: 134,
            name: "Pirates",
            link: "https://statsapi.mlb.com/api/v1/teams/134/"
        ),
        record: "7-15"
    )
}
