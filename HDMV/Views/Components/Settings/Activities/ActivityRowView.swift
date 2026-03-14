//
//  ActivityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct ActivityRowView: View {
    
    let activity: Activity
    let onCacheToggle: (Activity) -> Void

    var body: some View {
        HStack {
            IconView(iconString: activity.icon ?? "")
            Text(activity.name)
            Spacer()
            CacheToggleButton(model: activity) { a in
                onCacheToggle(a)
            }
            SyncStatusIndicator(status: activity.syncStatus)
        }
        .foregroundStyle(.primary)
    }
}
