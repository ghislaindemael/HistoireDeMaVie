//
//  NewCountrySheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

struct NewCountrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CountriesPageViewModel
    
    @State private var name: String = ""
    @State private var slug: String = ""
    
    private var isFormValid: Bool {
        !name.isEmpty && !slug.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Country Details") {
                    TextField("Slug", text: $slug)
                        .autocapitalization(.none)
                    TextField("Name", text: $name)
                    
                }
            }
            .navigationTitle("New Country")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await viewModel.createCountry(name: name, slug: slug)
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

