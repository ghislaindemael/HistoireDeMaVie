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
    @State private var isShowingOptionSelector = false
    let vehicle: Vehicle
        
    init(vehicle: Vehicle, modelContext: ModelContext) {
        self.vehicle = vehicle
        _viewModel = StateObject(wrappedValue: VehicleDetailSheetViewModel(model: vehicle, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    Picker("Vehicle Type", selection: $viewModel.editor.type) {
                        Text("All Types").tag(nil as VehicleType?)
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            type.labelView.tag(type as VehicleType?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
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
                    Toggle("Is Drivable", isOn: $viewModel.editor.isDrivable)
                }
                
                Section("Custom Options") {
                    let sortedMappings = viewModel.model.optionMappings.sorted { 
                        if $0.priority == $1.priority {
                            return $0.optionSlug < $1.optionSlug
                        }
                        return $0.priority < $1.priority 
                    }
                    
                    List {
                        ForEach(sortedMappings) { mapping in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(mapping.option?.name ?? mapping.optionSlug)
                                        .font(.headline)
                                    Spacer()
                                    Text("Priority: \(mapping.priority)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Toggle("Required", isOn: Binding(
                                    get: { mapping.required },
                                    set: { newValue in
                                        mapping.required = newValue
                                        mapping.markAsModified()
                                    }
                                ))
                            }
                        }
                        .onMove { indices, newOffset in
                            var mappings = sortedMappings
                            mappings.move(fromOffsets: indices, toOffset: newOffset)
                            for (index, mapping) in mappings.enumerated() {
                                mapping.priority = index
                                mapping.markAsModified()
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                let mapping = sortedMappings[index]
                                if let rid = mapping.rid {
                                    Task {
                                        _ = try? await DataLogOptionMappingService().delete(rid: rid)
                                    }
                                }
                                modelContext.delete(mapping)
                                viewModel.model.optionMappings.removeAll { $0.id == mapping.id }
                            }
                        }
                    }
                    
                    Button("Add Option") {
                        isShowingOptionSelector = true
                    }
                }

                
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
            .sheet(isPresented: $isShowingOptionSelector) {
                DataLogOptionSelectorView { selectedOption in
                    let newMapping = DataLogOptionMapping(
                        vehicleRid: viewModel.model.rid ?? 0,
                        optionSlug: selectedOption.slug,
                        priority: viewModel.model.optionMappings.count,
                        syncStatus: .unsynced
                    )
                    newMapping.vehicle = viewModel.model
                    newMapping.option = selectedOption
                    modelContext.insert(newMapping)
                    viewModel.model.optionMappings.append(newMapping)
                }
            }
        }
    }
    
}


