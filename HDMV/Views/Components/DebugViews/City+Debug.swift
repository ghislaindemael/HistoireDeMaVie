import SwiftUI

extension City: DebugViewable {
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
            NamedStringDisplayView(name: "Slug", value: slug)
            if let countryRid {
                Text("Country RID: \(countryRid)")
            } else {
                Text("Country RID: Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            if let country {
                Text("Country: \(country.name)")
            } else {
                Text("Country: Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
