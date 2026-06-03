//
//  MultiVehicleSelectorView.swift
//  HDMV
//

import SwiftUI
import SwiftData

struct MultiVehicleSelectorView: View {
    @Query(FetchDescriptor<Vehicle>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.name)]))
    private var allVehicles: [Vehicle]
    
    @Binding var selectedRids: [Int]
    
    var body: some View {
        List {
            if allVehicles.isEmpty {
                ContentUnavailableView("No Vehicles", systemImage: "car.slash", description: Text("Add cached vehicles in the Settings tab first."))
            } else {
                ForEach(allVehicles) { vehicle in
                    if let rid = vehicle.rid {
                        Button {
                            toggleSelection(for: rid)
                        } label: {
                            HStack {
                                Text(vehicle.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                
                                if selectedRids.contains(rid) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Vehicles")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleSelection(for rid: Int) {
        if let index = selectedRids.firstIndex(of: rid) {
            selectedRids.remove(at: index)
        } else {
            selectedRids.append(rid)
        }
    }
}
