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
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { editor.place_start_id },
                        set: { editor.place_start_id = $0 }
                    ))
                    PlaceSelectorView(selectedPlaceId: Binding(
                        get: { editor.place_end_id },
                        set: { editor.place_end_id = $0 }
                    ))
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
                
            }
            .navigationTitle("Edit Path")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(isFormValid: editor.isValid) {
                await onDone()
            }
        }
    }
    
    /// Handles the logic when the "Done" button is tapped.
    private func onDone() async {
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


