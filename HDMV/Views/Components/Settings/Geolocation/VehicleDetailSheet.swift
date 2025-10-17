//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

struct VehicleDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: VehicleDetailSheetViewModel
    let vehicle: Vehicle
        
    init(vehicle: Vehicle, modelContext: ModelContext) {
        self.vehicle = vehicle
        _viewModel = StateObject(wrappedValue: VehicleDetailSheetViewModel(vehicle: vehicle, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    Picker("Vehicle Type", selection: $viewModel.editor.type) {
                        Text("All Types").tag(nil as VehicleType?)
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            Text(type.label).tag(type as VehicleType?)
                        }
                    }
                    
                }
                
                Section("City"){
                    CitySelectorView(selectedCity: Binding(
                        get: { viewModel.editor.city },
                        set: { viewModel.editor.city = $0 }
                    ))
                }

                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
            }
            .navigationTitle("Edit Path")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
}


