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
    
    @State private var cityToEdit: City?
    
    var body: some View {
        NavigationStack {
            Form {
                countryFilter
                citiesList
            }
            .navigationTitle("Cities")
            .logPageToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                singleTapAction: { viewModel.createCity() },
                longPressAction: {}
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
                Text("Select").tag(nil as Country?)
                ForEach(countries) { country in
                    Text(country.name ?? "Unset").tag(country as Country?)
                }
            }
        }
    }
    
    @ViewBuilder
    private var citiesList: some View {
        Section("Cities") {
            ForEach(viewModel.filteredCities) { city in
                Button(action: {
                    cityToEdit = city
                }) {
                    CityRowView(city: city)

                }
                .buttonStyle(.plain)
                
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
