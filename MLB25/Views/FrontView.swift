//
//  FrontView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import SwiftUI

struct FrontView: View {
    @State private var isSheetPresented = false
    @State private var view = ""
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
            Spacer()
            HStack {
                Button {
                    view = "Team"
                    isSheetPresented = true
                } label: {
                    Text("Teams/Roster")
                }

                Button {
                    view = "Leader"
                    isSheetPresented = true
                } label: {
                    Text("Leaders")
                }

                Button {
                    view = "Search"
                    isSheetPresented = true
                } label: {
                    Text("Search")
                }
            }
            .buttonStyle(.glassProminent)
              
        }
        .padding()
//        .fullScreenCover(isPresented: $isSheetPresented) {
//            switch view {
//            case "Team":
//                NavigationStack {
//                    TeamView()
//                        .toolbar {
//                            ToolbarItem(placement: .topBarLeading) {
//                                Button("Close") { isSheetPresented = false }
//                            }
//                        }
//                }
//
//            case "Leader":
////                NavigationStack {
////                    //TODO:
////                        .toolbar {
////                            ToolbarItem(placement: .topBarLeading) {
////                                Button("Close") { isSheetPresented = false }
////                            }
////                        }
////                }
//
//            case "Search":
////                NavigationStack {
////                    //TODO:
////                        .toolbar {
////                            ToolbarItem(placement: .topBarLeading) {
////                                Button("Close") { isSheetPresented = false }
////                            }
////                        }
////                }
//
//            default:
//                // Fallback to avoid a blank screen if view isn't set yet
//                ZStack {
//                    Color.black.ignoresSafeArea()
//                    VStack(spacing: 20) {
//                        Text("No destination")
//                            .font(.title)
//                            .foregroundStyle(.white)
//                        Button("Dismiss") { isSheetPresented = false }
//                            .buttonStyle(.borderedProminent)
//                    }
//                }
//            }
//        }

//        .fullScreenCover(isPresented: $isSheetPresented) {
//            if (view == "Team"){
//                NavigationStack {
//                    TeamView()
//                }
//            } else if (view == "Leader"){
//                //TODO:
//            } else if (view == "Search"){
//                //TODO:
//            }
//        }
            
    }
}

#Preview {
    FrontView()
}
