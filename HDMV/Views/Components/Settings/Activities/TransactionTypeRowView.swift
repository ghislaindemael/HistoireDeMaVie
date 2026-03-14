//
//  ActivityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//

import SwiftUI

struct TransactionTypeRowView: View {
    
    let type: TransactionType
    let onCacheToggle: (TransactionType) -> Void
    
    var body: some View {
        HStack {
            IconView(iconString: type.icon ?? "")
            Text(type.name)
            Spacer()
            CacheToggleButton(model: type) { t in
                onCacheToggle(t)
            }
            SyncStatusIndicator(status: type.syncStatus)
        }
        .foregroundStyle(.primary)
    }
}
