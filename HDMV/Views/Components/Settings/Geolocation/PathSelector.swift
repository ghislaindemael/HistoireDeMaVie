//
//  PathSelector.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.11.2025.
//


import SwiftUI

struct PathSelector: View {
    @Binding var path: Path?
    @Binding var pathRid: Int?
    @Binding var isShowingSelector: Bool
    
    var body: some View {
        if let selectedPath = path {
            VStack(alignment: .leading, spacing: 8) {
                PathDisplayView(path: selectedPath)
                
                Button(role: .destructive,
                       action: {
                        withAnimation {
                            path = nil
                            pathRid = nil
                        }}) {
                            Label("Clear path", systemImage: "trash.fill")
                                .foregroundStyle(.red)
                        }
               
            }
        } else {
            Button(action: { isShowingSelector = true }) {
                Label("Select Existing Path", systemImage: "map")
            }
        }
    }
}
