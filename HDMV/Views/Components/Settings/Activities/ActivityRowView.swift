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
            IconView(iconString: activity.icon)
            Text(activity.name)
        }
        .foregroundStyle(.primary)
    }
}
