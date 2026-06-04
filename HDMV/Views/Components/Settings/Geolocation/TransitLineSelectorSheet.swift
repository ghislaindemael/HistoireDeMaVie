//
//  TransitLineSelectorSheet.swift
//  HDMV
//

import SwiftUI
import SwiftData

struct TransitLineSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TransitLine.name)
    private var lines: [TransitLine]
    
    var selectedVehicle: Vehicle?
    var onSelect: (TransitLine) -> Void
    
    @State private var showAllLines: Bool = false
    
    private var filteredLines: [TransitLine] {
        if showAllLines { return lines }
        
        return lines.filter { line in
            let hasRidRestrictions = !(line.allowedVehicleRids?.isEmpty ?? true)
            if !hasRidRestrictions {
                return true // Unrestricted line
            }
            
            guard let vehicle = selectedVehicle, let vRid = vehicle.rid else {
                return false // Line has restrictions, but no valid vehicle selected
            }
            
            if let rids = line.allowedVehicleRids, rids.contains(vRid) {
                return true
            }
            
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if filteredLines.isEmpty {
                    ContentUnavailableView("No Valid Transit Lines", systemImage: "tram", description: Text("No lines match the selected vehicle, or no lines exist."))
                } else {
                    ForEach(filteredLines) { line in
                        Button {
                            onSelect(line)
                            dismiss()
                        } label: {
                            HStack {
                                Text(line.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Transit Line")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("Show All Lines", isOn: $showAllLines)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle" + (showAllLines ? ".fill" : ""))
                    }
                }
            }
        }
    }
}
