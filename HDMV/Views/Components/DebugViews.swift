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
            
            Text("Percentage: \((percentage))%")
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

extension Trip: DebugViewable {
    
    var debugView: some View {
        VStack {
            Section("Identity & Sync") {
                LabeledContent("RID", value: self.rid?.description ?? "nil (local)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Sync Status")
                    Spacer()
                    SyncStatusIndicator(status: self.syncStatus)
                }
            }
            
            Section("Time") {
                LabeledContent("Start", value: self.timeStart.formatted(date: .numeric, time: .standard))
                LabeledContent("End", value: self.timeEnd?.formatted(date: .numeric, time: .standard) ?? "In Progress")
            }
            
            Section("Relationships") {
                LabeledContent("Parent Instance RID", value: self.parentInstanceRid?.description ?? "nil")
                LabeledContent("Parent Loaded", value: self.parentInstance != nil ? "✅ Yes" : "❌ No")
                
                LabeledContent("Vehicle RID", value: self.vehicleRid?.description ?? "nil")
                LabeledContent("Vehicle Loaded", value: self.vehicle != nil ? "✅ Yes" : "❌ No")
                
                LabeledContent("Place Start RID", value: self.placeStartRid?.description ?? "nil")
                LabeledContent("Place Start Loaded", value: self.placeStart != nil ? "✅ Yes" : "❌ No")
                
                LabeledContent("Place End RID", value: self.placeEndRid?.description ?? "nil")
                LabeledContent("Place End Loaded", value: self.placeEnd != nil ? "✅ Yes" : "❌ No")
                
                LabeledContent("Path RID", value: self.pathRid?.description ?? "nil")
                LabeledContent("Path Loaded", value: self.path != nil ? "✅ Yes" : "❌ No")
            }
            
            // MARK: - Details
            Section("Details") {
                LabeledContent("Am Driver", value: self.am_driver.description)
                LabeledContent("Details Text", value: self.details ?? "N/A")
                LabeledContent("Path String", value: self.path_str ?? "N/A")
            }
        }
    }
}
