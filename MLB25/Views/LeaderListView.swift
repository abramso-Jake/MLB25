//
//  LeaderListView.swift
//  MLB25
//
//  Created by Jake Abramson on 4/7/26.
//

import SwiftUI

struct LeaderListView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            VStack{
                Text("Aaron Judge is the Goat")
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
    LeaderListView()
}
