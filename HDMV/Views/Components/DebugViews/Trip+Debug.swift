import SwiftUI

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
                
                LabeledContent("Place Start RID", value: self.placeStartRid?.description ?? "nil")
                
                LabeledContent("Place End RID", value: self.placeEndRid?.description ?? "nil")
                
                LabeledContent("Path RID", value: self.pathRid?.description ?? "nil")
                
                LabeledContent("GeoJSON track proints", value: self.geojsonTrack?.coordinates.count.description ?? "nil")
            }
            
            // MARK: - Details
            Section("Details") {
                LabeledContent("Am Driver", value: self.amDriver.description)
                LabeledContent("Details Text", value: self.details ?? "N/A")
            }
        }
    }
    
    var debugText: String {
        var components: [String] = []
        components.append("--- Trip ---")
        components.append("Local ID: \(self.id.id)")
        components.append("RID: \(self.rid?.description ?? "nil (local)")")
        components.append("Sync Status: \(self.syncStatus.rawValue)")
        components.append("---")
        components.append("Time Start: \(self.timeStart.formatted())")
        components.append("Time End: \(self.timeEnd?.formatted() ?? "nil (In Progress)")")
        components.append("Am Driver: \(self.amDriver)")
        components.append("Details: \(self.details ?? "N/A")")
        components.append("---")
        components.append("Parent Instance RID: \(self.parentInstanceRid?.description ?? "nil")")
        components.append("-> Parent Loaded: \(self.parentInstance != nil ? "Yes" : "No")")
        components.append("Vehicle RID: \(self.vehicleRid?.description ?? "nil")")
        components.append("Place Start RID: \(self.placeStartRid?.description ?? "nil")")
        components.append("Place End RID: \(self.placeEndRid?.description ?? "nil")")
        components.append("Path RID: \(self.pathRid?.description ?? "nil")")
        components.append("------------")
        
        return components.joined(separator: "\n")
    }
}
