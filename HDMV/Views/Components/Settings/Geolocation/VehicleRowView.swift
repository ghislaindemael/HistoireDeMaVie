//
//  VehicleRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct VehicleRowView: View {
    
    let vehicle: Vehicle
    let onCacheToggle: (Vehicle) -> Void
    
    var body: some View {
        VStack{
            HStack {
                UnsettableTextView(
                    text: vehicle.type != .unset ? vehicle.label : "Unset",
                    font: .body,
                    isItalicized: vehicle.archived
                )
                Spacer()
                CatalogueRowControlsView(model: vehicle, onToggle: onCacheToggle)
            }
        }
    }
}
