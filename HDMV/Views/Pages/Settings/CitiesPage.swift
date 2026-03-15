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
        filter: #Predicate<City> { $0.country == nil },
        sort: \.name
    ) private var orphanedCities: [City]
    
    @State private var cityToEdit: City?
    
    var body: some View {
        NavigationStack {
            Form {
                countryFilter
                citiesList
            }
            .navigationTitle("Cities")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createCity() }
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
        if let selectedCountry = viewModel.selectedCountry {
            Section("Cities in \(selectedCountry.name)") {
                ForEach(selectedCountry.sortedCities) { city in
                    Button(action: { cityToEdit = city }) {
                        CityRowView(city: city) { c in
                            withAnimation(.snappy) {
                                viewModel.updateModel(c) { concreteCity in
                                    concreteCity.cache.toggle()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Section("Cities (No Country)") {
                ForEach(orphanedCities) { city in
                    Button(action: { cityToEdit = city }) {
                        CityRowView(city: city) { c in
                            withAnimation(.snappy) {
                                viewModel.updateModel(c) { concreteCity in
                                    concreteCity.cache.toggle()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
