//
//  CountriesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import SwiftUI
import SwiftData

struct CountriesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CountriesPageViewModel()
    
    @State private var countryToEdit: Country?
    @State private var searchText: String = ""
    
    private var filteredCountries: [Country] {
        guard !searchText.isEmpty else { return viewModel.items }
        return viewModel.items.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText) ||
            country.slug.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var unsetCountries: [Country] {
        filteredCountries.filter { $0.name == "Unset" || $0.name.isEmpty }
    }
    
    private var validCountries: [Country] {
        filteredCountries.filter { $0.name != "Unset" && !$0.name.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !unsetCountries.isEmpty {
                    Section("Needs Configuration / Unset") {
                        ForEach(unsetCountries) { country in
                            countryRow(country)
                        }
                    }
                }
                
                if !validCountries.isEmpty {
                    Section("Countries") {
                        ForEach(validCountries) { country in
                            countryRow(country)
                        }
                    }
                } else if unsetCountries.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Countries")
            .searchable(text: $searchText, prompt: "Search Countries")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createCountry() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $countryToEdit) { country in
                CountryDetailSheet(country: country, modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private func countryRow(_ country: Country) -> some View {
        Button {
            countryToEdit = country
        } label: {
            CountryRowView(country: country) { c in
                withAnimation(.snappy) {
                    viewModel.updateModel(c) { $0.cache.toggle() }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteItem(country)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
