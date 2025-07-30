//
//  PlacesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//

import SwiftUI
import SwiftData

struct PlacesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PlacesPageViewModel()
    
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter by City")) {
                    // The Picker is now bound to the ViewModel's selectedCity property
                    Picker("Select City", selection: $viewModel.selectedCity) {
                        Text("Select a City...").tag(nil as City?)
                        ForEach(viewModel.cities) { city in
                            Text(city.name).tag(city as City?)
                        }
                    }
                }
                
                if viewModel.selectedCity != nil {
                    Section(header: Text(viewModel.selectedCity?.name ?? "Places")) {
                        ForEach(viewModel.filteredPlaces) { place in
                            PlaceRowView(place: place) {
                                viewModel.toggleCache(for: place)
                            }
                        }
                        .onDelete(perform: deletePlace)
                    }
                } else {
                    Section {
                        Text("Please select a city to view its places.")
                    }
                }
            }
            .navigationTitle("Places")
            .standardConfigPageToolbar(
                refreshAction: {
                    await viewModel.refreshDataFromServer()
                },
                cacheAction: {
                    viewModel.cachePlacesForSelectedCity()
                },
                isShowingAddSheet: $isShowingAddSheet
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(isPresented: $isShowingAddSheet) {
                NewPlaceSheet(viewModel: viewModel, city: viewModel.selectedCity)
            }
        }
    }
    
    private func deletePlace(at offsets: IndexSet) {
        for index in offsets {
            let placeToArchive = viewModel.filteredPlaces[index]
            viewModel.archivePlace(for: placeToArchive)
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Country.self, City.self, Place.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let switzerland = Country(id: 1, slug: "ch", name: "Switzerland")
            context.insert(switzerland)
            
            let geneva = City(id: 10, slug: "geneva", name: "Geneva", rank: 2, country_id: 1)
            let zurich = City(id: 11, slug: "zurich", name: "Zürich", rank: 1, country_id: 1)
            context.insert(geneva)
            context.insert(zurich)
            
            context.insert(Place(id: 100, name: "Jet d'Eau", city_id: 10))
            context.insert(Place(id: 101, name: "CERN", city_id: 10))
            
            return container
        } catch { fatalError("Failed to create container: \(error)") }
    }()
    
    PlacesPage()
        .modelContainer(container)
        .environmentObject(SettingsStore())
}
