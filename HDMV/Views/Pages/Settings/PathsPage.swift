//
//  ActivitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//


import SwiftUI
import SwiftData

struct PathsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PathsPageViewModel()
    
    @Query(sort: \Path.name) private var paths: [Path]
    
    
    @Query(sort: \City.name) private var cities: [City]
    @Query private var places: [Place]
    
    @State private var pathToEdit: Path?
    @State private var selectedCity: City? = nil
    
    private var hasLocalChanges: Bool {
        return paths.contains(where: { $0.syncStatus != .synced })
    }
    
    private var filteredPaths: [Path] {
        guard let selectedCity = selectedCity else {
            return paths
        }
        
        let placeIDsInCity = places
            .filter { $0.city_id == selectedCity.id }
            .map { $0.id }
        
        let placeIDSet = Set(placeIDsInCity)
        
        return paths.filter { path in
            guard let startID = path.place_start_id, let endID = path.place_end_id else {
                return false
            }
            return placeIDSet.contains(startID) || placeIDSet.contains(endID)
        }
    }

    
    var body: some View {
        NavigationStack {
            Form {
                cityFilterPicker
                pathsList
            }
            .navigationTitle("Paths")
            .logPageToolbar(
                refreshAction: { await viewModel.syncWithServer() },
                syncAction: { await viewModel.syncLocalChanges() },
                singleTapAction: { viewModel.createLocalPath() },
                longPressAction: {}
            )
            .sheet(item: $pathToEdit) { path in
                PathDetailSheet(path: path)
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .syncingOverlay(viewModel.isLoading)
        }
    }
    
    @ViewBuilder
    private var cityFilterPicker: some View {
        Section("Filter") {
            Picker("City", selection: $selectedCity) {
                Text("All Cities").tag(nil as City?)
                
                ForEach(cities) { city in
                    Text(city.name).tag(city as City?)
                }
            }
        }
    }
    
    
    @ViewBuilder
    private var pathsList: some View {
        Section() {
            ForEach(filteredPaths) { path in
                Button(action: {
                    pathToEdit = path
                }) {
                    PathRowView(path: path)
                    
                }
                .buttonStyle(.plain)
            }
        }
    }
}
