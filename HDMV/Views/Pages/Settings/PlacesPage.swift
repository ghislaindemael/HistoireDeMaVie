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
    
    @State private var isShowingCreateSheet = false
    @State private var selectedCity: City?
    
    private var filteredPlaces: [Place] {
        guard let city = selectedCity else { return [] }
        return viewModel.places.filter { $0.city_id == city.id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter by City")) {
                    Picker("Select City", selection: $selectedCity) {
                        Text("Select a City...").tag(nil as City?)
                        ForEach(viewModel.cities) { city in
                            Text(city.name).tag(city as City?)
                        }
                    }
                }
                
                if selectedCity != nil {
                    Section(header: Text(selectedCity?.name ?? "Places")) {
                        ForEach(filteredPlaces) { place in
                            PlaceRowView(place: place)
                        }
                    }
                } else {
                    Section {
                        Text("Please select a city to view its places.")
                    }
                }
            }
            .navigationTitle("Places")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { Task { await viewModel.refreshDataFromServer() }}) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateSheet.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                NewPlaceSheet(viewModel: viewModel)
            }
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
    
    return PlacesPage().modelContainer(container)
}
