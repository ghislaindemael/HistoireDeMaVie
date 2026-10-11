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
                        Picker("Type", selection: Binding(
                            get: { viewModel.editor.geometry?.type ?? .point },
                            set: { newType in
                                let lat = viewModel.editor.geometry?.centerLatitude ?? 0.0
                                let lon = viewModel.editor.geometry?.centerLongitude ?? 0.0
                                let radius = viewModel.editor.geometry?.radiusMeters ?? 50.0
                                switch newType {
                                case .point:
                                    viewModel.editor.geometry = .point(latitude: lat, longitude: lon)
                                case .circle:
                                    viewModel.editor.geometry = .circle(latitude: lat, longitude: lon, radiusMeters: radius)
                                case .lineString:
                                    viewModel.editor.geometry = .line(coordinates: viewModel.editor.geometry?.lineCoordinates ?? [[lon, lat]])
                                case .polygon:
                                    viewModel.editor.geometry = .polygon(coordinates: viewModel.editor.geometry?.polygonCoordinates ?? [[[lon, lat]]])
                                }
                            }
                        )) {
                            Text("Point (Spot / Venue)").tag(PlaceGeometryType.point)
                            Text("Zone / Circle (Park / Piazza)").tag(PlaceGeometryType.circle)
                            Text("Line (Street / Path)").tag(PlaceGeometryType.lineString)
                            Text("Polygon (Zone boundary)").tag(PlaceGeometryType.polygon)
                        }
                        
                        HStack {
                            Text("Latitude")
                            Spacer()
                            TextField("e.g. 47.3769", value: Binding(
                                get: { viewModel.editor.geometry?.centerLatitude ?? 0.0 },
                                set: { newLat in
                                    let lon = viewModel.editor.geometry?.centerLongitude ?? 0.0
                                    let radius = viewModel.editor.geometry?.radiusMeters ?? 50.0
                                    let type = viewModel.editor.geometry?.type ?? .point
                                    if type == .circle {
                                        viewModel.editor.geometry = .circle(latitude: newLat, longitude: lon, radiusMeters: radius)
                                    } else {
                                        viewModel.editor.geometry = .point(latitude: newLat, longitude: lon)
                                    }
                                }
                            ), format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                        }
                        
                        HStack {
                            Text("Longitude")
                            Spacer()
                            TextField("e.g. 8.5417", value: Binding(
                                get: { viewModel.editor.geometry?.centerLongitude ?? 0.0 },
                                set: { newLon in
                                    let lat = viewModel.editor.geometry?.centerLatitude ?? 0.0
                                    let radius = viewModel.editor.geometry?.radiusMeters ?? 50.0
                                    let type = viewModel.editor.geometry?.type ?? .point
                                    if type == .circle {
                                        viewModel.editor.geometry = .circle(latitude: lat, longitude: newLon, radiusMeters: radius)
                                    } else {
                                        viewModel.editor.geometry = .point(latitude: lat, longitude: newLon)
                                    }
                                }
                            ), format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                        }
                        
                        if viewModel.editor.geometry?.type == .circle {
                            HStack {
                                Text("Radius (meters)")
                                Spacer()
                                TextField("e.g. 100", value: Binding(
                                    get: { viewModel.editor.geometry?.radiusMeters ?? 50.0 },
                                    set: { newRadius in
                                        let lat = viewModel.editor.geometry?.centerLatitude ?? 0.0
                                        let lon = viewModel.editor.geometry?.centerLongitude ?? 0.0
                                        viewModel.editor.geometry = .circle(latitude: lat, longitude: lon, radiusMeters: newRadius)
                                    }
                                ), format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                            }
                        }
                        
                        if viewModel.editor.geometry != nil {
                            Button("Clear GPS Coordinates", role: .destructive) {
                                viewModel.editor.geometry = nil
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


