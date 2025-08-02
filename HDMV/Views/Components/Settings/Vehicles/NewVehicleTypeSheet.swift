//
//  NewVehicleTypeSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import SwiftUI

struct NewVehicleTypeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VehicleTypesPageViewModel
    
    @State private var payload = NewVehicleTypePayload()
    
    private var isFormValid: Bool {
        !payload.slug.isEmpty && !payload.name.isEmpty && !payload.icon.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Slug", text: $payload.slug)
                        .autocapitalization(.none)
                    TextField("Name", text: $payload.name)
                    TextField("Icon", text: $payload.icon)
                }
            }
            .navigationTitle("New Country")
            .standardSheetToolbar(
                isFormValid: isFormValid,
                onDone: {
                    await viewModel.createVehicleType(payload:payload)
                }
            )
        }
    }
}

