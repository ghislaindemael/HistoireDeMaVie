//
//  DebugViews.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//

import SwiftUI

extension ActivityInstance {
    
    var debugView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ID: \(id)")
            HStack {
                Text("Start: \(time_start.formatted(date: .abbreviated, time: .shortened))")
                
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            if let time_end {
                Text("End: \(time_end.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            if let activity_id {
                Text("Activity ID: \(activity_id)")
            } else {
                Text("Activity: Unset")
                    .bold()
                    .foregroundStyle(.red)
                
            }
            
            Text("Percentage: \(percentage ?? 100)%")
            
            Text("Details: \(details ?? "N/A")")
            
            if decodedActivityDetails != nil {
                Text("Activity Details:")
                Text(decodedActivityDetails.debugDescription)
            }
            
            
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
}

extension PersonInteraction {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let time_start {
                    Text("Start: \(time_start.formatted(date: .abbreviated, time: .shortened))")
                } else {
                    Text("Start: Unknown")
                }
                
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            if let time_end {
                Text("End: \(time_end.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            if let parent_id = parent_activity_id {
                Text("Parent activity ID: \(parent_id)")
            } else {
                Text("Independent interaction")
            }
            
            if person_id > 0  {
                Text("Person ID: \(person_id)")
            } else {
                Text("Person: Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            
            Text("Percentage: \((percentage ?? 100))%")
            Text("Details: \(details ?? "N/A")")
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
