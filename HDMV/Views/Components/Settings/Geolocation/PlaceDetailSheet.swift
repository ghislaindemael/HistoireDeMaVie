//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

struct PlaceDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: PlaceDetailSheetViewModel
    let place: Place
        
    init(place: Place, modelContext: ModelContext) {
        self.place = place
        _viewModel = StateObject(wrappedValue: PlaceDetailSheetViewModel(model: place, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    CitySelectorView(selectedCity: Binding(
                        get: { viewModel.editor.city },
                        set: { newCity in
                            viewModel.editor.city = newCity
                            viewModel.editor.cityRid = newCity?.rid
                        }
                    ))
                }

                Section("Usage") {
                    Toggle("Favorite", isOn: $viewModel.editor.isFavorite)
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
                Section("Restrictions") {
                    NavigationLink {
                        MultiVehicleSelectorView(selectedRids: $viewModel.editor.allowedVehicleRids)
                    } label: {
                        HStack {
                            Text("Allowed Specific Vehicles")
                            Spacer()
                            Text("\(viewModel.editor.allowedVehicleRids.count) selected")
                                .foregroundStyle(viewModel.editor.allowedVehicleRids.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                    NavigationLink {
                        MultiVehicleTypeSelectorView(selectedSlugs: $viewModel.editor.allowedVehicleTypeSlugs)
                    } label: {
                        HStack {
                            Text("Allowed Generic Types")
                            Spacer()
                            Text("\(viewModel.editor.allowedVehicleTypeSlugs.count) selected")
                                .foregroundStyle(viewModel.editor.allowedVehicleTypeSlugs.isEmpty ? .secondary : .primary)
                        }
                    }
                }
                
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
}


