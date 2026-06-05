//
//  LifeContextRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

struct LifeContextRowView: View {
    
    let context: LifeContext
    let onCacheToggle: (LifeContext) -> Void

    var body: some View {
        HStack {
            if let icon = context.icon, !icon.isEmpty {
                IconView(iconString: icon)
            }
            
            
            Text(context.name)
                .italic(context.archived)
            
            Spacer()
                
            if context.archived {
                Image(systemName: "archivebox")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            CacheToggleButton(model: context) { c in
                onCacheToggle(c)
            }
            
            if let start = context.timeStart {
                Text(start.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            SyncStatusIndicator(status: context.syncStatus)
        }
        .foregroundStyle(context.archived ? .secondary : .primary)
        .opacity(context.archived ? 0.7 : 1.0)
    }
}
