//
//  PathsPage.swift
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
    @State private var searchText: String = ""
    
    private var hasLocalChanges: Bool {
        return paths.contains(where: { $0.syncStatus != .synced })
    }
    
    private var cityFilteredPaths: [Path] {
        guard let selectedCity = selectedCity else {
            return paths
        }
        
        let placeRidSet = Set(places
            .filter { $0.cityRid == selectedCity.rid }
            .compactMap { $0.rid })
        
        return paths.filter { path in
            let hasStart = path.placeStartRids.contains { placeRidSet.contains($0) }
            let hasEnd = path.placeEndRids.contains { placeRidSet.contains($0) }
            return hasStart || hasEnd
        }
    }
    
    private var searchFilteredPaths: [Path] {
        guard !searchText.isEmpty else { return cityFilteredPaths }
        let matchingPlaceRids = Set(
            places
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .compactMap { $0.rid }
        )
        return cityFilteredPaths.filter { path in
            path.name.localizedCaseInsensitiveContains(searchText) ||
            path.placeStartRids.contains { matchingPlaceRids.contains($0) } ||
            path.placeEndRids.contains { matchingPlaceRids.contains($0) }
        }
    }
    
    private var unsetPaths: [Path] {
        searchFilteredPaths.filter { $0.name == "Unset" || $0.name.isEmpty }
    }
    
    private var validPaths: [Path] {
        searchFilteredPaths.filter { $0.name != "Unset" && !$0.name.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                cityFilterPicker
                pathsList
            }
            .navigationTitle("Paths")
            .searchable(text: $searchText, prompt: "Search Paths")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createLocalPath() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .sheet(item: $pathToEdit) { path in
                PathDetailSheet(path: path, modelContext: modelContext)
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
        if !unsetPaths.isEmpty {
            Section("Needs Configuration / Unset") {
                ForEach(unsetPaths) { path in
                    pathRow(path)
                }
            }
        }
        
        if !validPaths.isEmpty {
            Section("Paths") {
                ForEach(validPaths) { path in
                    pathRow(path)
                }
            }
        } else if unsetPaths.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
    
    @ViewBuilder
    private func pathRow(_ path: Path) -> some View {
        Button(action: {
            pathToEdit = path
        }) {
            PathRowView(
                path: path,
                showSyncStatus: true,
                onToggle: { p in
                    withAnimation(.snappy) {
                        viewModel.updateModel(p) { $0.cache.toggle() }
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteItem(path)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
