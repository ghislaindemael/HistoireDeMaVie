//
//  PathSelector.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.11.2025.
//


import SwiftUI

struct PathSelector: View {
    let path: Path?
    let pathRid: Int?
    @Binding var isShowingSelector: Bool
    
    var onSelect: (Path, Int) -> Void
    var onClear: () -> Void
    
    var body: some View {
        if let selectedPath = path {
            VStack(alignment: .leading) {
                PathDisplayView(path: selectedPath)
                
                Divider().padding(.vertical, 4)
                
                Button(role: .destructive) {
                    withAnimation {
                        onClear()
                    }
                } label: {
                    Label("Clear path", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        } else if pathRid != nil {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Spacer()
                Text("Uncached Path (ID: \(pathRid!))")
            }
            .foregroundColor(.orange)
            .fontWeight(.semibold)
        } else {
            Button {
                isShowingSelector = true
            } label: {
                Label("Select Existing Path", systemImage: "map")
            }
        }
    }
}

