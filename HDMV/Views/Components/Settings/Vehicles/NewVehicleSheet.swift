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
    
    @State private var name: String = ""
    @State private var selectedVehicleType: VehicleType?
    @State private var cityIdString: String = ""
    
    private var isFormValid: Bool {
        !name.isEmpty && selectedVehicleType != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Vehicle Type", selection: $selectedVehicleType) {
                        Text("Select a type").tag(nil as VehicleType?)
                        ForEach(viewModel.vehicleTypes) { type in
                            Text(type.name).tag(type as VehicleType?)
                        }
                    }
                    
                    TextField("City ID (Optional)", text: $cityIdString)
                        .keyboardType(.numberPad)
                }
                
                
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await createVehicle()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func createVehicle() async {
        guard let selectedVehicleType = selectedVehicleType else {
            return
        }
                
        let cityId = Int(cityIdString)
        
        await viewModel.createVehicle(
            name: name,
            type: selectedVehicleType,
            city_id: cityId
        )
                
        dismiss()
    }
    
}
