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
    
    @Bindable var path: Path
    @State private var editor: PathEditor
    
    @State private var isShowingPathSelector = false
    
    init(path: Path) {
        self.path = path
        _editor = State(initialValue: PathEditor(from: path))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: Binding(
                        get: { editor.name ?? "" },
                        set: { editor.name = $0 }
                    ))
                    TextField("Details", text: Binding(
                        get: { editor.details ?? "" },
                        set: { editor.details = $0 }
                    ))
                }
                Section("Start place"){
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { editor.place_start_id },
                        set: { editor.place_start_id = $0 }
                    ))
                }
                Section("End place"){
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { editor.place_end_id },
                        set: { editor.place_end_id = $0 }
                    ))
                }
                pathSection
                
            
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
                
            }
            .navigationTitle("Edit Path")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                onDone()
            }
            .sheet(isPresented: $isShowingPathSelector) {
                PathSelectorSheet { selectedPathId in
                    if editor.path_ids == nil {
                        editor.path_ids = []
                    }
                    if !editor.path_ids!.contains(selectedPathId) {
                        editor.path_ids!.append(selectedPathId)
                    }
                }
            }
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Paths")) {
            
                TextField(
                    "Distance",
                    text: Binding(
                        get: { editor.distance.map { String($0) } ?? "" },
                        set: { newValue in
                            if let value = Double(newValue) {
                                editor.distance = value
                            } else {
                                editor.distance = nil
                            }
                        }
                    )
                )
                .keyboardType(.decimalPad)
            
            ForEach(editor.path_ids ?? [], id: \.self) { pathId in
                PathDisplayView(pathId: pathId)
            }
            .onMove { indices, newOffset in
                editor.path_ids = (editor.path_ids ?? [])
                editor.path_ids?.move(fromOffsets: indices, toOffset: newOffset)
            }
            .onDelete { indices in
                editor.path_ids = (editor.path_ids ?? [])
                editor.path_ids?.remove(atOffsets: indices)
            }
            
            Button(action: { isShowingPathSelector = true }) {
                Label("Add path", systemImage: "plus.circle.fill")
            }
        }
    }
    
    /// Handles the logic when the "Done" button is tapped.
    private func onDone() {
        path.syncStatus = .local
        editor.apply(to: path)
        
        do {
            try modelContext.save()
            print("✅ Path \(path.id) saved to context.")
        } catch {
            print("❌ Failed to save path to context: \(error)")
        }
        
    }
    
    
}


