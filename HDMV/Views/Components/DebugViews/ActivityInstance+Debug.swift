import SwiftUI

extension ActivityInstance: DebugViewable {
    
    var debugView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            HStack {
                Text("Start: \(timeStart.formatted(date: .abbreviated, time: .shortened))")
                
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            if let timeEnd {
                Text("End: \(timeEnd.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            if let activityRid {
                Text("Activity RID: \(activityRid)")
            } else {
                Text("Activity: Unset")
                    .bold()
                    .foregroundStyle(.red)
                
            }
            
            if let parentInstanceRid {
                Text("Parent ActivityInstance RID: \(parentInstanceRid)")
            } else if let parentTripRid {
                Text("Parent Trip RID: \(parentTripRid)")
            } else {
                Text("Parent RID: Unset")
                    .bold()
                    .foregroundStyle(.orange)
                
            }
            
            Text("Percentage: \(percentage)%")
            
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
