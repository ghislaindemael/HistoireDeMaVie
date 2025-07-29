//
//  NewCitySheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct NewCitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CitiesPageViewModel
    
    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var rank: Int = 4
    @State private var selectedCountry: Country?
    
    private var isFormValid: Bool {
        !name.isEmpty && !slug.isEmpty && selectedCountry != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("City Details") {
                    TextField("Slug", text: $slug)
                        .autocapitalization(.none)
                    TextField("Name", text: $name)
                    
                }
                
                Section("Classification") {
                    Picker("Country", selection: $selectedCountry) {
                        Text("Select a Country").tag(nil as Country?)
                        ForEach(viewModel.countries) { country in
                            Text(country.name).tag(country as Country?)
                        }
                    }
                    Picker("Rank", selection: $rank) {
                        ForEach(1...5, id: \.self) { rankValue in
                            Text("Rank \(rankValue)").tag(rankValue)
                        }
                    }
                }
            }
            .navigationTitle("New City")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            if let country = selectedCountry {
                                await viewModel.createCity(name: name, slug: slug, country: country, rank: rank)
                            }
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

