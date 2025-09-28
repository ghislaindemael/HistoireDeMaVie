//
//  CreateVehicleView.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import SwiftUI
import SwiftData

struct NewVehicleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: VehiclesPageViewModel
    
    @State private var payload: NewVehiclePayload = NewVehiclePayload()
    
    private var isFormValid: Bool {
        !payload.name.isEmpty
    }
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Name", text: $payload.name)
                    
                    Picker("Vehicle Type", selection: $payload.type) {
                        Text("Select a type").tag(nil as VehicleType?)
                        ForEach(VehicleType.allCases, id: \.self ) { type in
                            Text(type.name).tag(type as VehicleType?)
                        }
                    }
                    
                    Picker("City", selection: Binding(
                        get: { payload.city_id ?? -1 },
                        set: { payload.city_id = $0 == -1 ? nil : $0 }
                    )) {
                        Text("None").tag(-1)
                        ForEach(viewModel.cities, id: \.id) { city in
                            Text(city.name).tag(city.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                
            }
            .standardSheetToolbar(
                isFormValid: isFormValid,
                onDone: {
                    await viewModel.createVehicle(payload:payload)
                }
            )
        }
    }
}
