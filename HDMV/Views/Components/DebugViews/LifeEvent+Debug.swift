import SwiftUI

extension LifeEvent: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let rid = rid {
                    Text("Remote ID: \(rid)")
                } else {
                    Text("Unsynced")
                        .bold()
                        .foregroundStyle(.orange)
                }
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            Text("Type: \(type?.name ?? "Unknown Type")")
                .font(.headline)
            
            Text("Start: \(timeStart.formatted(date: .abbreviated, time: .shortened))")
            if let timeEnd {
                Text("End: \(timeEnd.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            Divider()
            
            if let parentInstanceRid {
                Text("Parent Instance RID: \(parentInstanceRid) (\(parentInstance != nil ? "✅ Loaded" : "❌ Missing"))")
            } else if let parentTripRid {
                Text("Parent Trip RID: \(parentTripRid) (\(parentTrip != nil ? "✅ Loaded" : "❌ Missing"))")
            } else {
                Text("Parent: Independent")
                    .bold()
                    .foregroundStyle(.orange)
            }
            
            if let details {
                Text("Details: \(details)")
            }
            
            if let log_details = decodedLogDetails {
                Text("Log Options Mapping Count: \(log_details.options?.count ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
