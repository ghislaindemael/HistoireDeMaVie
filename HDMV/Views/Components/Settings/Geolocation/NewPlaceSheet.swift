//
//  NewPlaceSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct NewPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PlacesPageViewModel
    
    @State private var name: String = ""
    @State private var selectedCity: City?
    @State private var isSaving = false
    
    private var isFormValid: Bool { !name.isEmpty && selectedCity != nil }
    
    /// Custom initializer to accept a pre-selected city.
    /// - Parameters:
    ///   - viewModel: The view model for handling data operations.
    ///   - city: The city that should be pre-selected in the picker.
    init(viewModel: PlacesPageViewModel, city: City? = nil) {
        self.viewModel = viewModel
        // Initialize the @State property with the passed-in city.
        self._selectedCity = State(initialValue: city)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Place Details") {
                    TextField("Name", text: $name)
                }
                
                Section("Location") {
                    Picker("City", selection: $selectedCity) {
                        Text("Select a City...").tag(nil as City?)
                        ForEach(viewModel.cities) { city in
                            Text(city.name).tag(city as City?)
                        }
                    }
                }
                
                if isSaving {
                    Section { ProgressView() }
                }
            }
            .navigationTitle("New Place")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            isSaving = true
                            if let city = selectedCity {
                                await viewModel.createPlace(name: name, city: city)
                            }
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
    }
}
