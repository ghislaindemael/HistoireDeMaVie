import SwiftUI

extension Vehicle: DebugViewable {
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
            NamedStringDisplayView(name: "TypeSlug", value: typeSlug)
            NamedStringDisplayView(name: "Type", value: type.rawValue)
            LabeledContent("City RID", value: self.cityRid?.description ?? "nil")
            LabeledContent("City Loaded", value: self.city != nil ? "✅ Yes" : "❌ No")
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
