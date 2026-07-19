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
            UnsettableTextView(
                text: activity.name,
                font: .body,
                isItalicized: activity.archived
            )
            Spacer()
            CatalogueRowControlsView(model: activity, onToggle: onCacheToggle)
        }
        .foregroundStyle(.primary)
    }
}
