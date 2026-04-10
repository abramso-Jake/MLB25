//
//  FrontView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import SwiftUI

struct FrontListView: View {
    enum Des: Identifiable {
        case team
        case leader
        case search
        
        var id: Self { self }
    }

    @State private var selectedView: Des?
    var body: some View {
        VStack{
            Image("icon")
                .resizable()
                .scaledToFit()
            Text("Welcome to MLB Stats! Click a desired function to get started!")
                .font(Font.custom("Times New Roman", size: 20))
                .font(.title2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .fontWeight(.medium)
            Spacer()
            HStack {
                Button {
                    selectedView = .team
                } label: {
                    Text("Teams/Roster")
                }

                Button {
                    selectedView = .leader
                } label: {
                    Text("Leaders")
                }

                Button {
                    selectedView = .search
                } label: {
                    Text("Search")
                }
            }
            .buttonStyle(.glassProminent)
              
        }
        .padding()
        .fullScreenCover(item: $selectedView) { destination in
            switch destination {
            case .team:
                TeamListView()
            case .leader:
                LeadersListView()
            case .search:
                SearchListView()
            }
        }
            
    }
}

#Preview {
    FrontListView()
}
