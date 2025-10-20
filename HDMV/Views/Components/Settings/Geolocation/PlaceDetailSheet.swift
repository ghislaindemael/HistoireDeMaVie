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
        _viewModel = StateObject(wrappedValue: PlaceDetailSheetViewModel(place: place, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
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
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
}


