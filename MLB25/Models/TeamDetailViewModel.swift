import Foundation

@MainActor
@Observable
class TeamDetailViewModel {
    var teamDetail: TeamDetail?
    var extraInfo: TeamExtraInfo?
    var isLoading = false
    var errorMessage = ""

    func getData(for team: Team) async {
        isLoading = true
        errorMessage = ""
        teamDetail = nil
        extraInfo = nil

        let urlString = "https://statsapi.mlb.com/api/v1/teams/\(team.id)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let response = try? JSONDecoder().decode(TeamDetailResponse.self, from: data),
                  let fetchedTeam = response.teams.first else {
                errorMessage = "Could not decode team data."
                isLoading = false
                return
            }

            teamDetail = fetchedTeam
            extraInfo = TeamExtraData.infoByTeamID[team.id]
            isLoading = false
        } catch {
            errorMessage = "Network error."
            isLoading = false
        }
    }
}
