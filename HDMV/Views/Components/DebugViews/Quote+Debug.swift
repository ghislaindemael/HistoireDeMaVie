import SwiftUI
import SwiftData

extension Quote: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            
            NamedStringDisplayView(name: "Text", value: text)
            NamedStringDisplayView(name: "Author", value: authorString)
            NamedStringDisplayView(name: "Context", value: context)
            
            Text("Person RID: \(personRid?.description ?? "nil")")
            Text("Parent Interaction RID: \(parentInteractionRid?.description ?? "nil")")
            Text("Parent Instance RID: \(parentInstanceRid?.description ?? "nil")")
            Text("Parent Trip RID: \(parentTripRid?.description ?? "nil")")
            
            Text("Has Media Details: \(mediaDetailsData != nil ? "Yes" : "No")")
            
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
