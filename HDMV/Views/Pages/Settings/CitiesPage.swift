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
    
    @State private var isShowingCreateSheet = false
    @State private var selectedCountry: Country?
    
    private var filteredCities: [City] {
        guard let country = selectedCountry else {
            return viewModel.cities
        }
        return viewModel.cities.filter { $0.country_id == country.id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    Picker("Select Country", selection: $selectedCountry) {
                        Text("Select a Country...").tag(nil as Country?)
                        ForEach(viewModel.countries) { country in
                            Text(country.name).tag(country as Country?)
                        }
                    }
                }
                
                if selectedCountry != nil {
                    Section(header: Text(selectedCountry?.name ?? "Cities")) {
                        ForEach(filteredCities) { city in
                            CityRowView(
                                city: city,
                                onRankChanged: { newRank in
                                    viewModel.updateRank(for: city, to: newRank)
                                },
                                onCacheToggle: {
                                    viewModel.toggleCache(for: city)
                                }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let cityToArchive = filteredCities[index]
                                viewModel.archiveCity(for: cityToArchive)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("Please select a country")
                    }
                }
            }
            .navigationTitle("Cities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateSheet.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.refreshDataFromServer()
                        }
                    }) {
                        Image(systemName: "icloud.and.arrow.down.fill")
                    }
                }
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                NewCitySheet(viewModel: viewModel)
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
            
            let switzerland = Country(id: 1, slug: "ch", name: "Switzerland")
            let france = Country(id: 2, slug: "fr", name: "France")
            
            container.mainContext.insert(switzerland)
            container.mainContext.insert(france)
            
            container.mainContext.insert(City(id: 10, slug: "geneva", name: "Geneva", rank: 2, country_id: 1))
            container.mainContext.insert(City(id: 11, slug: "aubonne", name: "Aubonne-Pizy-Montherod", rank: 1, country_id: 1))
            container.mainContext.insert(City(id: 12, slug: "lausanne", name: "Lausanne", rank: 3, country_id: 1))
            container.mainContext.insert(City(id: 20, slug: "paris", name: "Paris", rank: 1, country_id: 2))

            return container
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }()
    
    CitiesPage().modelContainer(container)
}
