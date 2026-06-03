//
//  MultiVehicleTypeSelectorView.swift
//  HDMV
//

import SwiftUI

struct MultiVehicleTypeSelectorView: View {
    @Binding var selectedSlugs: [String]
    
    // Get all defined vehicle types except unset
    private let vehicleTypes = VehicleType.allCases.filter { $0 != .unset }
    
    var body: some View {
        List {
            ForEach(vehicleTypes, id: \.self) { type in
                Button {
                    toggleSelection(for: type.rawValue)
                } label: {
                    HStack {
                        Text(type.label)
                            .foregroundStyle(.primary)
                        Spacer()
                        
                        if selectedSlugs.contains(type.rawValue) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Vehicle Types")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleSelection(for slug: String) {
        if let index = selectedSlugs.firstIndex(of: slug) {
            selectedSlugs.remove(at: index)
        } else {
            selectedSlugs.append(slug)
        }
    }
}
