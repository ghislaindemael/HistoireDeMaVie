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
                    PlaceTypeSelectorView(selectedPlaceType: $viewModel.editor.placeType)
                    if !viewModel.editor.isVirtual {
                        TextField("Address", text: Binding(
                            get: { viewModel.editor.address ?? "" },
                            set: { viewModel.editor.address = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }

                Section("Options") {
                    Toggle("Virtual / Moving Place", isOn: $viewModel.editor.isVirtual)
                    
                    if viewModel.editor.isVirtual {
                        Text("Virtual places represent moving or non-fixed contexts (e.g. roaming in train, car, flights). They are excluded from stay suggestions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Toggle("Reachable in Trip", isOn: Binding(
                        get: { viewModel.editor.decodedOptions?.reachableInTrip ?? true },
                        set: { newValue in
                            if viewModel.editor.decodedOptions == nil {
                                viewModel.editor.decodedOptions = PlaceOptions()
                            }
                            viewModel.editor.decodedOptions?.reachableInTrip = newValue
                        }
                    ))
                }
                
                if !viewModel.editor.isVirtual {
                    Section("Location & Geometry") {
                        if let geom = viewModel.editor.geometry {
                            HStack {
                                Label(geom.typeTitle, systemImage: geom.iconName)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(geom.summaryText)
                                    .foregroundStyle(.secondary)
                            }
                            
                            PlaceGeometryMapView(geometry: geom)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } else {
                            HStack {
                                Label("No Coordinates Set", systemImage: "location.slash")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Managed in DB / Web")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
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


