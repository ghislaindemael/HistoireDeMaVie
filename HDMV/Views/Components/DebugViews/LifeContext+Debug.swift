//
//  LifeContext+Debug.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

extension LifeContext: DebugViewable {
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
            NamedStringDisplayView(name: "Sync Status", value: syncStatusRaw)
            
            if let icon = icon {
                NamedStringDisplayView(name: "Icon", value: icon)
            }
            
            NamedStringDisplayView(name: "Selectable", value: selectable ? "Yes" : "No")
            NamedStringDisplayView(name: "Archived", value: archived ? "Yes" : "No")
            NamedStringDisplayView(name: "Cached", value: cache ? "Yes" : "No")
            
            if let start = timeStart {
                NamedStringDisplayView(name: "Start", value: start.formatted())
            }
            if let end = timeEnd {
                NamedStringDisplayView(name: "End", value: end.formatted())
            }
            
            if let parentRid = parentRid {
                Text("Parent id: \(parentRid)")
            }
            Text("Children count: \(children.count)")
        }
    }
}
