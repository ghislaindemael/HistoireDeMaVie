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
    
    @Query(FetchDescriptor<City>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.name)]))
    private var cities: [City]
    
    @State private var placeToEdit: Place?

    var body: some View {
        NavigationStack {
            Form {
                cityFilter
                placesList
            }
            .navigationTitle("Places")
            .logPageToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                singleTapAction: { viewModel.createPlace() },
                longPressAction: {}
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $placeToEdit) { place in
                PlaceDetailSheet(place: place, modelContext: modelContext)
            }
        }
    }
    
    
    @ViewBuilder
    private var cityFilter: some View {
        Section("City Filter") {
            Picker("City", selection: $viewModel.selectedCity) {
                Text("Select").tag(nil as City?)
                ForEach(cities) { city in
                    Text(city.name).tag(city as City?)
                }
            }
        }
    }
    
    @ViewBuilder
    private var placesList: some View {
        Section("Places") {
            ForEach(viewModel.filteredPlaces) { place in
                Button(action: {
                    placeToEdit = place
                }) {
                    PlaceRowView(place: place)
                }
                .buttonStyle(.plain)
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
            
            let switzerland = Country(slug: "ch", name: "Switzerland")
            context.insert(switzerland)
            
            let geneva = City(rid: 10, slug: "geneva", name: "Geneva", countryRid: 1)
            let zurich = City(rid: 11, slug: "zurich", name: "Zürich", countryRid: 1)
            context.insert(geneva)
            context.insert(zurich)
            
            context.insert(Place(rid: 100, name: "Jet d'Eau", cityRid: 10))
            context.insert(Place(rid: 101, name: "CERN", cityRid: 10))
            
            return container
        } catch { fatalError("Failed to create container: \(error)") }
    }()
    
    PlacesPage()
        .modelContainer(container)
        .environmentObject(SettingsStore())
}
