//
//  ActivityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct ActivityRowView: View {
    
    let activity: Activity
    
    var body: some View {
        HStack {
            IconView(iconString: activity.icon ?? "")
            Text(activity.name)
            Spacer()
            if !activity.cache {
                IconView(iconString: "iphone.gen1.slash", tint: .red)
            }
            SyncStatusIndicator(status: activity.syncStatus)
        }
        .foregroundStyle(.primary)
    }
}
