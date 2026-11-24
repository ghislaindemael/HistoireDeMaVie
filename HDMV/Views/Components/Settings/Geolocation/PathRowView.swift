//
//  PathRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//

import SwiftUI

struct PathRowView: View {
    let path: Path
    let showSyncStatus: Bool
    let bubble: Bool
    let isReversed: Bool
    var onToggle: ((Path) -> Void)? = nil
    
    init(
        path: Path,
        showSyncStatus: Bool = false,
        bubble: Bool = false,
        isReversed: Bool = false,
        onToggle: ((Path) -> Void)? = nil
    ) {
        self.path = path
        self.showSyncStatus = showSyncStatus
        self.bubble = bubble
        self.isReversed = isReversed
        self.onToggle = onToggle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(path.name)
                    .bold(path.name == "Unset")
                    .foregroundStyle(path.name == "Unset" ? .red : .primary)
                
                if isReversed {
                    Label("Reversed", systemImage: "arrow.left.arrow.right")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                } else if path.isBidirectional {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                if showSyncStatus || onToggle != nil || path.archived {
                    CatalogueRowControlsView(model: path, onToggle: onToggle)
                }
            }
            
            ForEach(path.placeStartRids, id: \.self) { startRid in
                PlaceDisplayView(placeRid: startRid)
            }
            
            ForEach(path.placeEndRids, id: \.self) { endRid in
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(.secondary)
                    PlaceDisplayView(placeRid: endRid)
                }
            }
            
            PathMetricsRowView(metrics: path.metrics, showTitle: false, bubble: false)
            
            if let details = path.details, !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
