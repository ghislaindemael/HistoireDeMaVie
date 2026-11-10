//
//  DataMediaItemRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

struct DataMediaItemRowView: View {
    
    let item: DataMediaItem
    let onCacheToggle: (DataMediaItem) -> Void

    var body: some View {
        HStack {
            if let icon = item.icon, !icon.isEmpty {
                IconView(iconString: icon)
            }
            
            Text(item.name)
                .italic(item.archived)
            
            Spacer()
                
            CatalogueRowControlsView(model: item, onToggle: onCacheToggle)
        }
        .foregroundStyle(item.archived ? .secondary : .primary)
        .opacity(item.archived ? 0.7 : 1.0)
    }
}
