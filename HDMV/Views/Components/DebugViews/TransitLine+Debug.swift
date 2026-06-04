import SwiftUI

extension TransitLine: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            NamedStringDisplayView(name: "Name", value: name)
            LabeledContent("Allowed Vehicles", value: allowedVehicleRids?.map(String.init).joined(separator: ", ") ?? "All")
            LabeledContent("Stops Loaded", value: String(stops?.count ?? 0))
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
