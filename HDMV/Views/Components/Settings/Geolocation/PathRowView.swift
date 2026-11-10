//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PathRowView: View {
    let path: Path
    let showSyncStatus: Bool
    let bubble: Bool
    var onToggle: ((Path) -> Void)? = nil
    
    init(path: Path, showSyncStatus: Bool = false, bubble: Bool = false, onToggle: ((Path) -> Void)? = nil) {
        self.path = path
        self.showSyncStatus = showSyncStatus
        self.bubble = bubble
        self.onToggle = onToggle
    }
    
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text(path.name)
                    .bold(path.name == "Unset")
                    .foregroundStyle(path.name == "Unset" ? .red : .primary)
                Spacer()
                if showSyncStatus || onToggle != nil || path.archived {
                    CatalogueRowControlsView(model: path, onToggle: onToggle)
                }
            }
            PlaceDisplayView(placeRid: path.placeStart?.rid)
            HStack {
                Image(systemName: "arrow.turn.down.right")
                PlaceDisplayView(placeRid: path.placeEnd?.rid)
            }
            PathMetricsRowView(metrics: path.metrics, showTitle: false, bubble: false)
            if let details = path.details {
                Text(details)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
        }
        .if(bubble) { view in
            view
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryBackground)
                )
        }
    }
    
}
