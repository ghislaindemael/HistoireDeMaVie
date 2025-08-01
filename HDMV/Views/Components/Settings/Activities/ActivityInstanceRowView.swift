//
//  ActivityInstanceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct ActivityInstanceRowView: View {
    let instance: ActivityInstance
    let activities: [Activity]
    
    private var activity: Activity? {
        activities.first { $0.id == instance.activity_id }
    }
    
    var body: some View {
        HStack {
            IconView(iconString: activity?.icon ?? "questionmark.circle")
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(activity?.name ?? "Unassigned Activity")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(instance.time_start, style: .time)
                    Text("-")
                    if let timeEnd = instance.time_end {
                        Text(timeEnd, style: .time)
                    } else {
                        Text("In Progress").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            SyncStatusIndicator(status: instance.syncStatus)
        }
        .padding(.vertical, 4)
    }
}
