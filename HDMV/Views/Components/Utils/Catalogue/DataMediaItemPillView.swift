//
//  DataMediaItemPillView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataMediaItemPillView: View {
    var explicitMediaItem: DataMediaItem?
    var itemId: Int?
    var progress: String?
    
    @Query private var queriedItems: [DataMediaItem]
    
    init(mediaItem: DataMediaItem? = nil, itemId: Int? = nil, progress: String? = nil) {
        self.explicitMediaItem = mediaItem
        self.itemId = itemId
        self.progress = progress
        
        if let id = itemId {
            let filter = #Predicate<DataMediaItem> { $0.rid == id }
            _queriedItems = Query(filter: filter)
        } else {
            _queriedItems = Query(filter: #Predicate<DataMediaItem> { _ in false })
        }
    }
    
    private var resolvedItem: DataMediaItem? {
        if let item = explicitMediaItem { return item }
        return queriedItems.first
    }
    
    var body: some View {
        HStack {
            if let icon = resolvedItem?.icon {
                IconView(iconString: icon, size: 14)
            } else {
                Image(systemName: "tv.fill")
                    .font(.system(size: 14))
            }
            
            Text(resolvedItem?.name ?? "Unknown Item")
                .fontWeight(.semibold)
                .font(.caption)
            
            if let progress = progress, !progress.isEmpty {
                Text("— \(progress)")
                    .font(.caption2)
                    .opacity(0.8)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.indigo.opacity(0.15))
        )
        .foregroundColor(.indigo)
    }
}
