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
    
    @State private var isShowingPathSelector = false
    @State private var isShowingGpxFileImporter = false
    
    init(path: Path, modelContext: ModelContext) {
        self.path = path
        _viewModel = StateObject(wrappedValue: PathDetailSheetViewModel(path: path, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: Binding(
                        get: { viewModel.editor.name ?? "" },
                        set: { viewModel.editor.name = $0 }
                    ))
                    TextField("Details", text: Binding(
                        get: { viewModel.editor.details ?? "" },
                        set: { viewModel.editor.details = $0 }
                    ))
                }
                Section("Start place"){
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { viewModel.editor.place_start_id },
                        set: { viewModel.editor.place_start_id = $0 }
                    ))
                }
                Section("End place"){
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { viewModel.editor.place_end_id },
                        set: { viewModel.editor.place_end_id = $0 }
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
            .sheet(isPresented: $isShowingPathSelector) {
                PathSelectorSheet(
                    startPlaceId: path.place_start_id,
                    endPlaceId: path.place_end_id,
                    onPathSelected: viewModel.addPathSegment
                )
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
            
            Text("Distance: \(viewModel.editor.metrics?.distance ?? 0, specifier: "%.2f") m")
            Text("Elevation Gain (D+): \(viewModel.editor.metrics?.elevationGain ?? 0, specifier: "%.1f") m")
            Text("Elevation Loss (D-): \(viewModel.editor.metrics?.elevationLoss ?? 0, specifier: "%.1f") m")
            Text("GeoJSON track points: \(viewModel.editor.geojson_track?.coordinates.count ?? 0)")
            
            ForEach(viewModel.editor.path_ids ?? [], id: \.self) { pathId in
                PathDisplayView(pathId: pathId)
            }
            .onMove { indices, newOffset in
                viewModel.editor.path_ids = (viewModel.editor.path_ids ?? [])
                viewModel.editor.path_ids?.move(fromOffsets: indices, toOffset: newOffset)
            }
            .onDelete { indices in
                viewModel.editor.path_ids = (viewModel.editor.path_ids ?? [])
                viewModel.editor.path_ids?.remove(atOffsets: indices)
            }
            
            if viewModel.editor.path_ids == nil {
                Button(action: { isShowingGpxFileImporter = true }) {
                    Label("Import GPX", systemImage: "square.and.arrow.up.circle.fill")
                }
            }
            
            if viewModel.editor.metrics == nil {
                Button(action: { isShowingPathSelector = true }) {
                    Label("Add path", systemImage: "plus.circle.fill")
                }
            }
            
        }
    }
    
    /// Handles the logic when the "Done" button is tapped.
    private func onDone() {
        viewModel.editor.apply(to: path)
        path.syncStatus = .local

        do {
            try modelContext.save()
            print("✅ Path \(path.id) saved to context.")
        } catch {
            print("❌ Failed to save path to context: \(error)")
        }
        
    }
    
    
}


