import SwiftUI
import MapKit

struct TeamDetailListView: View {
    let team: Team
    @State private var detailVM = TeamDetailViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if let teamDetail = detailVM.teamDetail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(teamDetail.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let locationName = teamDetail.locationName {
                                Text(locationName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        GroupBox("Team Information") {
                            VStack(alignment: .leading, spacing: 10) {
                                detailRow(title: "Franchise", value: teamDetail.franchiseName ?? "N/A")
                                detailRow(title: "Club Name", value: teamDetail.clubName ?? "N/A")
                                detailRow(title: "Abbreviation", value: teamDetail.abbreviation ?? "N/A")
                                detailRow(title: "First Year of Play", value: teamDetail.firstYearOfPlay ?? "N/A")
                                detailRow(title: "League", value: teamDetail.league?.name ?? "N/A")
                                detailRow(title: "Division", value: teamDetail.division?.name ?? "N/A")
                                detailRow(title: "Venue", value: teamDetail.venue?.name ?? "N/A")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    if let extra = $detailVM.extraInfo {
                        GroupBox("Location") {
                            VStack(alignment: .leading, spacing: 10) {
                                detailRow(title: "Location", value: extra?.locationText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        GroupBox("Description") {
                            Text(extra.description)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        let stadiumCoordinate = CLLocationCoordinate2D(
                            latitude: extra.latitude,
                            longitude: extra.longitude
                        )
                        
                        Map {
                            Marker(
                                detailVM.teamDetail?.venue?.name ?? team.name,
                                coordinate: stadiumCoordinate
                            )
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        GroupBox("Stadium") {
                            AsyncImage(url: URL(string: extra.stadiumImageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 220)
                            }
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        GroupBox("Jerseys") {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Home")
                                    .font(.headline)
                                
                                AsyncImage(url: URL(string: extra.homeJerseyURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 180)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                
                                Text("Away")
                                    .font(.headline)
                                
                                AsyncImage(url: URL(string: extra.awayJerseyURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 180)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    if !detailVM.errorMessage.isEmpty {
                        Text(detailVM.errorMessage)
                            .foregroundStyle(.red)
                            .font(.headline)
                    }
                }
                .padding()
            }
            
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
            id: 121,
            name: "Mets",
            link: "https://statsapi.mlb.com/api/v1/teams/121/"
        )
    )
}
