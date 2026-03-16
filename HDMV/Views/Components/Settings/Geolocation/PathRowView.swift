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
    
    init(path: Path, showSyncStatus: Bool = false, bubble: Bool = false) {
        self.path = path
        self.showSyncStatus = showSyncStatus
        self.bubble = bubble
    }
    
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                if let name = path.name {
                    Text(name)
                } else {
                    Text("Name unset")
                        .bold()
                        .foregroundStyle(.red)
                }
                if(showSyncStatus){
                    Spacer()
                    SyncStatusIndicator(status: path.syncStatus)
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
