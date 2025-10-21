//
//  DebugViews.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//

import SwiftUI

protocol DebugViewable {
    associatedtype DebugView: View
    @ViewBuilder var debugView: DebugView { get }
}

extension DebugViewable {
    var erasedDebugView: AnyView { AnyView(debugView) }
}

extension Activity: DebugViewable {
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
            if let parentRid = parentRid {
                Text("Parent id: \(parentRid)")
            }
        }
    }
}

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
                Text("Start: \(time_start.formatted(date: .abbreviated, time: .shortened))")
                
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            if let time_end {
                Text("End: \(time_end.formatted(date: .abbreviated, time: .shortened))")
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

extension Country: DebugViewable {
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
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}

extension Path: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ID: \(id)")
            Text("Name: \(name ?? "Unset")")
            Text("Details: \(details ?? "Unset")")
            Text("Start place id: \(placeStart?.rid ?? -1)")
            Text("End place id: \(placeEnd?.rid ?? -1)")
        }
    }
}

extension Interaction: DebugViewable {
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
            
            if let parent_id = parentInstanceRid {
                Text("Parent instance ID: \(parent_id)")
            } else {
                Text("Independent interaction")
            }
            
            if let pid = personRid  {
                Text("Person RID: \(pid)")
            } else {
                Text("Person RID : Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            if let person = person  {
                Text("Person: \(person.fullName)")
            } else {
                Text("Person : Unset")
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

extension Person: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rid {
                Text(verbatim: "RID: \(rid)")
            } else {
                Text("RID: –")
                    .foregroundStyle(.secondary)
            }
            NamedStringDisplayView(name: "Slug", value: slug)
            NamedStringDisplayView(name: "Name", value: name)
            NamedStringDisplayView(name: "Family name", value: familyName)
            NamedStringDisplayView(name: "Surname", value: surname, unsetTint: .yellow)
        }
    }
}

extension Place: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rid {
                Text(verbatim: "RID: \(rid)")
            } else {
                Text("RID: –")
                    .foregroundStyle(.secondary)
            }
            Text("Name: \(name ?? "Unset")")
            Text("City rid: \(city?.rid ?? -1)")
        }
    }
}
