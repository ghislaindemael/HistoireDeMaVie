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
    
    @State private var payload = NewCountryPayload()

    
    private var isFormValid: Bool {
        !payload.slug.isEmpty && !payload.name.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Slug", text: $payload.slug)
                        .autocapitalization(.none)
                    TextField("Name", text: $payload.name)
                }
            }
            .navigationTitle("New Country")
            .standardSheetToolbar(
                isFormValid: isFormValid,
                onDone: {
                    await viewModel.createCountry(payload: payload)
                }
            )
        }
    }
}

