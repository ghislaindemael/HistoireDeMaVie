//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

struct PathDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: PathDetailSheetViewModel
    let path: Path
    
    @State private var isShowingGpxFileImporter = false
    @State private var isShowingTrackMap = false
    
    init(path: Path, modelContext: ModelContext) {
        self.path = path
        _viewModel = StateObject(wrappedValue: PathDetailSheetViewModel(model: path, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Details", text: $viewModel.editor.details.orEmpty())
                    Toggle("Bidirectional (A ↔ B)", isOn: $viewModel.editor.isBidirectional)
                }
                Section("Endpoints") {
                    NavigationLink {
                        MultiPlaceSelectorView(
                            selectedRids: $viewModel.editor.placeStartRids,
                            title: "Start Places"
                        )
                    } label: {
                        HStack {
                            Text("Start Places")
                            Spacer()
                            Text("\(viewModel.editor.placeStartRids.count) selected")
                                .foregroundStyle(viewModel.editor.placeStartRids.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                    NavigationLink {
                        MultiPlaceSelectorView(
                            selectedRids: $viewModel.editor.placeEndRids,
                            title: "End Places"
                        )
                    } label: {
                        HStack {
                            Text("End Places")
                            Spacer()
                            Text("\(viewModel.editor.placeEndRids.count) selected")
                                .foregroundStyle(viewModel.editor.placeEndRids.isEmpty ? .secondary : .primary)
                        }
                    }
                }
                pathSection
                
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
            
                UsageSectionView(isCached: $viewModel.editor.cache, isArchived: $viewModel.editor.archived)
                
            }
            .navigationTitle("Edit Path")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
            .fileImporter(
                isPresented: $isShowingGpxFileImporter,
                allowedContentTypes: [.gpx],
                onCompletion: viewModel.handleFileImport
            )
            .sheet(isPresented: $isShowingTrackMap) {
                if let track = viewModel.editor.geojson_track {
                    TrackMapView(
                        track: track,
                        title: viewModel.editor.name.isEmpty ? "Path Track" : viewModel.editor.name,
                        strokeColor: .orange
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Paths")) {
            
            HStack {
                Text("Distance (m)")
                Spacer()
                TextField("Distance (m)", value: $viewModel.editor.metrics.distance, format: .number)
                .keyboardType(.decimalPad)
            }
            Text("Elevation Gain (D+): \(viewModel.editor.metrics.elevationGain, specifier: "%.1f") m")
            Text("Elevation Loss (D-): \(viewModel.editor.metrics.elevationLoss, specifier: "%.1f") m")
            Text("GeoJSON track points: \(viewModel.editor.geojson_track?.coordinates.count ?? 0)")
            
            if let track = viewModel.editor.geojson_track {
                Button(action: { isShowingTrackMap = true }) {
                    Label("View GPS Track", systemImage: "map")
                        .foregroundStyle(.blue)
                }
            }
            
            Button(action: { isShowingGpxFileImporter = true }) {
                Label("Import GPX", systemImage: "square.and.arrow.up.circle.fill")
            }
        }
    }
    
}


