//
//  SearchView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import SwiftUI

struct SearchListView: View {
    @State private var searchVM = SearchViewModel()
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    TextField("Search Player", text: $searchVM.searchText)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.trailing, 30)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray, lineWidth: 1)
                        )
                        .overlay{
                            HStack {
                                Spacer()
                                if !searchVM.searchText.isEmpty {
                                    Button {
                                        searchVM.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                        .onChange(of: searchVM.searchText) {
                            Task {
                                await searchVM.searchPlayers()
                            }
                        }
                }
                .padding()
                
                if searchVM.isLoading{
                    Spacer()
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(4)
                    Spacer()
                } else if !searchVM.errorMessage.isEmpty {
                    Spacer()
                    Text(searchVM.errorMessage)
                    Spacer()
                } else {
                    List(searchVM.results) { player in
                        NavigationLink {
                            PlayerListView(
                                player: Roster(
                                    person: Person(
                                        id: player.id,
                                        fullName: player.fullName,
                                        link: player.link
                                    ),
                                    position: Position(
                                        name: player.positionName,
                                        abbreviation: player.positionAbbreviation
                                    )
                                ),
                                entry: .search
                            )
                        } label: {
                            VStack(alignment: .leading) {
                                Text((player.fullName))
                                    .font(.headline)
                                Text(player.positionName)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .listStyle(.plain)
                    
                }
            }
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "chevron.left", role: .close) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Player Search:")
        }
    }
}

#Preview {
    NavigationStack{
        SearchListView()
    }
}
