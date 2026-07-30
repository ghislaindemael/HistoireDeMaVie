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
    var mediaDetails: MediaDetails?
    
    @Query private var queriedItems: [DataMediaItem]
    
    init(mediaItem: DataMediaItem? = nil, itemId: Int? = nil, progress: String? = nil, mediaDetails: MediaDetails? = nil) {
        self.explicitMediaItem = mediaItem
        self.itemId = itemId
        self.progress = progress
        self.mediaDetails = mediaDetails
        
        if let id = itemId ?? mediaDetails?.itemId {
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
    
    private var displayProgress: String? {
        if let md = mediaDetails {
            var parts: [String] = []
            
            if let t = md.tome { parts.append("T\(t)") }
            
            if let s = md.season {
                let epStr = md.episode != nil ? "E\(md.episode!)" : ""
                parts.append("S\(s)\(epStr)")
            } else if let e = md.episode {
                parts.append("E\(e)")
            }
            
            if let time = md.time {
                if time >= 60 {
                    parts.append("\(time/60)h\(time%60)m")
                } else {
                    parts.append("\(time)m")
                }
            }
            if let perc = md.percentage { parts.append("\(perc)%") }
            if let p = md.progress, !p.isEmpty { parts.append(p) }
            
            if !parts.isEmpty {
                return parts.joined(separator: " - ")
            }
        }
        return progress
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
            
            if let disp = displayProgress, !disp.isEmpty {
                Text("— \(disp)")
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
