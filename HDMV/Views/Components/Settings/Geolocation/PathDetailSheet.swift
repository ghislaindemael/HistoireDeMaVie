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
    
    init(path: Path, modelContext: ModelContext) {
        self.path = path
        _viewModel = StateObject(wrappedValue: PathDetailSheetViewModel(model: path, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    TextField("Details", text: $viewModel.editor.details.orEmpty())
                }
                Section("Start place"){
                    PlaceSelectorView(selectedPlace: Binding(
                        get: { viewModel.editor.placeStart },
                        set: { viewModel.editor.placeStart = $0 }
                    ))
                }
                Section("End place"){
                    PlaceSelectorView(selectedPlace: Binding(
                        get: { viewModel.editor.placeEnd},
                        set: { viewModel.editor.placeEnd = $0 }
                    ))
                }
                pathSection
                
            
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
            .fileImporter(
                isPresented: $isShowingGpxFileImporter,
                allowedContentTypes: [.gpx],
                onCompletion: viewModel.handleFileImport
            )
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
            
            Button(action: { isShowingGpxFileImporter = true }) {
                Label("Import GPX", systemImage: "square.and.arrow.up.circle.fill")
            }
        }
    }
    
}


