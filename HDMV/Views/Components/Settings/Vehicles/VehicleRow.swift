//
//  VehicleRow.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//


//
//  VehicleRow.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import SwiftUI

struct VehicleRow: View {
    let vehicle: Vehicle
    let label: String
    
    // An action to perform, passed in from the parent
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack() {
            Text(label)
                .font(.headline)
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: vehicle.favourite ? "star.fill" : "star")
                    .foregroundColor(vehicle.favourite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let vehicle = Vehicle(
        id: 1, name: "Test", favourite: true, type: 1
    )
    
    VehicleRow(vehicle: vehicle, label: "Test label", onToggleFavorite: {})
}
