//
//  LeaderListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import SwiftUI

struct LeadersListView: View {
    @State private var leadersVM = LeadersViewModel()
    @Environment(\.dismiss) var dismiss
    let seasons = ["2026", "2025", "2024", "2023", "2022"]

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Group", selection: $leadersVM.selectedGroup) {
                    Text("Hitting").tag(LeaderGroup.hitting)
                    Text("Pitching").tag(LeaderGroup.pitching)
                }
                .pickerStyle(.palette)
                .padding(.horizontal)
                

                Picker("Season", selection: $leadersVM.selectedSeason) {
                    ForEach(seasons, id: \.self) { season in
                        Text(season).tag(season)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                if leadersVM.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(4)
                    Spacer()
                } else if !leadersVM.errorMessage.isEmpty {
                    Spacer()
                    Text(leadersVM.errorMessage)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if leadersVM.selectedGroup == .hitting {
                                ForEach(HittingLeaderCategory.allCases) { category in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(category.title)
                                            .font(.title3)
                                            .fontWeight(.bold)

                                        ForEach(Array((leadersVM.hittingLeaders[category] ?? []).prefix(7))) { leader in
                                            HStack {
                                                Text("\(leader.rank). \(leader.person?.fullName ?? "Unknown")")
                                                Spacer()
                                                Text(leader.value)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            } else {
                                ForEach(PitchingLeaderCategory.allCases) { category in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(category.title)
                                            .font(.title3)
                                            .fontWeight(.bold)

                                        ForEach(Array((leadersVM.pitchingLeaders[category] ?? []).prefix(7))) { leader in
                                            HStack {
                                                Text("\(leader.rank). \(leader.person?.fullName ?? "Unknown")")
                                                Spacer()
                                                Text(leader.value)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Stat Leaders")
            .task {
                await leadersVM.loadLeaders()
            }
            .onChange(of: leadersVM.selectedGroup) {
                Task { await leadersVM.loadLeaders() }
            }
            .onChange(of: leadersVM.selectedSeason) {
                Task { await leadersVM.loadLeaders() }
            }
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "chevron.left", role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LeadersListView()
}


