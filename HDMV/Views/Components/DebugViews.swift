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

extension Path {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ID: \(id)")
            Text("Name: \(name ?? "Unset")")
            Text("Details: \(details ?? "Unset")")
            Text("Start place id: \(place_start_id ?? -1)")
            Text("End place id: \(place_end_id ?? -1)")
            Text("Distance: \(distance ?? 0)")
        }
    }
}

extension PersonInteraction {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            if let parent_id = parent_activity_id {
                Text("Parent activity ID: \(parent_id)")
            } else {
                Text("Independent interaction")
            }
            
            if let pid = person_id  {
                Text("Person ID: \(pid)")
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
