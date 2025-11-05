//
//  CityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import SwiftUI
import SwiftData

struct CityDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: CityDetailSheetViewModel
    let city: City
        
    init(city: City, modelContext: ModelContext) {
        self.city = city
        _viewModel = StateObject(wrappedValue: CityDetailSheetViewModel(model: city, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    TextField("Slug", text: $viewModel.editor.slug.orEmpty())
                    CountrySelectorView(selectedCountry: $viewModel.editor.country)
                }

                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
            }
            .navigationTitle("Edit City")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
}


