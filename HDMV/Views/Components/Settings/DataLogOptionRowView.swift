//
//  DataLogOptionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataLogOptionRowView: View {
    let option: DataLogOption
    let onToggleCache: (DataLogOption) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.name)
                    .font(.headline)
                HStack {
                    Text(option.slug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                    Text(option.typeRaw.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            CacheToggleButton(model: option, onToggle: onToggleCache)
            SyncStatusIndicator(status: option.syncStatus)
        }
    }
}
