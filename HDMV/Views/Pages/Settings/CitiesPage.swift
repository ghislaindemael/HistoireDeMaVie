//
//  CitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//

import SwiftUI
import SwiftData

struct CitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CitiesPageViewModel()
    
    @Query(FetchDescriptor<Country>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.name)]))
    private var countries: [Country]
    
    @Query(
        filter: #Predicate<City> { $0.country == nil && $0.parentCity == nil },
        sort: \.slug
    ) private var orphanedCities: [City]
    
    @State private var cityToEdit: City?
    @State private var searchText: String = ""
    @Query(sort: \City.name) private var allCities: [City]
    
    private var unsetCities: [City] {
        allCities.filter { $0.name.isUnset() }
    }
    
    private var searchResults: [City] {
        guard !searchText.isEmpty else { return [] }
        return allCities.filter { city in
            city.name.isNotUnset() && (
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.slug.localizedCaseInsensitiveContains(searchText)
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if searchText.isEmpty {
                    countryFilter
                }
                citiesList
            }
            .navigationTitle("Cities")
            .searchable(text: $searchText, prompt: "Search Cities")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createCity() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $cityToEdit) { city in
                CityDetailSheet(city: city, modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var countryFilter: some View {
        Section("Country Filter") {
            Picker("Country", selection: $viewModel.selectedCountry) {
                Text("No country").tag(nil as Country?)
                ForEach(countries) { country in
                    Text(country.name).tag(country as Country?)
                }
            }
        }
    }
    
    @ViewBuilder
    private var citiesList: some View {
        if !unsetCities.isEmpty && searchText.isEmpty {
            Section("Needs Configuration / Unset") {
                ForEach(unsetCities) { city in
                    Button(action: { cityToEdit = city }) {
                        CityRowView(city: city) { c in
                            withAnimation(.snappy) {
                                viewModel.updateModel(c) { $0.cache.toggle() }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteItem(unsetCities[index])
                    }
                }
            }
        }
        
        if !searchText.isEmpty {
            if !searchResults.isEmpty {
                Section("Search Results") {
                    ForEach(searchResults) { city in
                        Button(action: { cityToEdit = city }) {
                            CityRowView(city: city) { c in
                                withAnimation(.snappy) {
                                    viewModel.updateModel(c) { $0.cache.toggle() }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else if let selectedCountry = viewModel.selectedCountry {
            let validRoots = selectedCountry.rootCities.filter { $0.name.isNotUnset() }
            Section("Cities in \(selectedCountry.name)") {
                ForEach(validRoots) { city in
                    CityNodeView(city: city, viewModel: viewModel, cityToEdit: $cityToEdit)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteItem(validRoots[index])
                    }
                }
            }
        } else {
            let validOrphans = orphanedCities.filter { $0.name.isNotUnset() }
            Section("Cities (No Country)") {
                ForEach(validOrphans) { city in
                    CityNodeView(city: city, viewModel: viewModel, cityToEdit: $cityToEdit)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteItem(validOrphans[index])
                    }
                }
            }
        }
    }
}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([Country.self, City.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            
            let switzerland = Country(slug: "ch", name: "Switzerland")
            
            container.mainContext.insert(switzerland)
            
            container.mainContext.insert(City(slug: "geneva", name: "Geneva", countryRid: 1))
            container.mainContext.insert(City(slug: "aubonne", name: "Aubonne-Pizy-Montherod", countryRid: 1, archived: true))
            container.mainContext.insert(City(slug: "lausanne", name: "Lausanne", countryRid: 1))
            
            return container
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }()
    
    CitiesPage().modelContainer(container)
}
