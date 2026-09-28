//
//  CompareSearchSheet.swift
//  MLB25
//

import SwiftUI

/// The player search from the Search tab, presented as a sheet. Picking a
/// result hands a Roster back to whichever column opened it.
struct CompareSearchSheet: View {

    let side: String
    let onSelect: (Roster) -> Void

    @State private var searchVM = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchField
                results
            }
            .navigationTitle("Add Player \u{2014} \(side)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)

            TextField("Search player", text: $searchVM.searchText)
                .autocorrectionDisabled()
                .onChange(of: searchVM.searchText) {
                    Task {
                        // SearchViewModel.searchPlayers() returns early below 3
                        // characters, so there is no point calling it sooner.
                        if searchVM.searchText.count >= 3 {
                            await searchVM.searchPlayers()
                        } else {
                            searchVM.results = []
                            searchVM.errorMessage = ""
                        }
                    }
                }

            if !searchVM.searchText.isEmpty {
                Button {
                    searchVM.searchText = ""
                    searchVM.results = []
                    searchVM.errorMessage = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private var results: some View {
        if searchVM.searchText.count < 3 {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)

                Text("Search for an MLB player")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Type at least 3 letters to search.")
                    .foregroundStyle(.secondary)
            }
            Spacer()

        } else if searchVM.isLoading {
            Spacer()
            ProgressView()
                .tint(.blue)
                .scaleEffect(4)
            Spacer()

        } else if !searchVM.errorMessage.isEmpty {
            Spacer()
            Text(searchVM.errorMessage)
                .foregroundStyle(.red)
            Spacer()

        } else if searchVM.results.isEmpty {
            Spacer()
            Text("No players found.")
                .foregroundStyle(.secondary)
            Spacer()

        } else {
            List(searchVM.results) { player in
                Button {
                    onSelect(roster(from: player))
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.fullName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("\(player.positionName) \u{2022} \(player.positionAbbreviation)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("Add")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    /// SearchPlayer and Roster carry the same information in different shapes.
    /// This is the same conversion SearchListView does before pushing
    /// PlayerListView.
    private func roster(from player: SearchPlayer) -> Roster {
        Roster(
            person: Person(
                id: player.id,
                fullName: player.fullName,
                link: player.link
            ),
            position: Position(
                name: player.positionName,
                abbreviation: player.positionAbbreviation
            )
        )
    }
}
