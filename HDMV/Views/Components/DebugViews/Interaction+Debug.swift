import SwiftUI

extension Interaction: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            if let parent_id = parentInstanceRid {
                Text("Parent instance ID: \(parent_id)")
            } else {
                Text("Independent interaction")
            }
            
            // MARK: Updated to handle Arrays
            if personRids.isEmpty  {
                Text("Person RIDs : Empty")
                    .bold()
                    .foregroundStyle(.red)
            } else {
                Text("Person RIDs: \(personRids.map { String($0) }.joined(separator: ", "))")
            }
            
            if persons.isEmpty  {
                Text("Persons : Empty")
                    .bold()
                    .foregroundStyle(.red)
            } else {
                Text("Persons: \(persons.map { $0.fullName }.joined(separator: ", "))")
            }
            
            Text("Percentage: \(percentage)%")
            Text("Details: \(details ?? "N/A")")
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
