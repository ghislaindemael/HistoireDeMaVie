//
//  VehiclesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import SwiftUI
import SwiftData

struct VehiclesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel = VehiclesPageViewModel()
    
    @State private var vehicleToEdit: Vehicle?
    @State private var searchText: String = ""
    
    private var searchFilteredVehicles: [Vehicle] {
        guard !searchText.isEmpty else { return viewModel.filteredVehicles }
        return viewModel.filteredVehicles.filter { vehicle in
            vehicle.name.localizedCaseInsensitiveContains(searchText) ||
            (vehicle.type?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var unsetVehicles: [Vehicle] {
        searchFilteredVehicles.filter { $0.name == "Unset" || $0.name.isEmpty }
    }
    
    private var validVehicles: [Vehicle] {
        searchFilteredVehicles.filter { $0.name != "Unset" && !$0.name.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                typeFilter
                vehiclesList
            }
            .navigationTitle("Vehicles")
            .searchable(text: $searchText, prompt: "Search Vehicles")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createVehicle() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .onChange(of: viewModel.selectedType) { viewModel.refreshFilteredVehicles()
            }
            .sheet(item: $vehicleToEdit) { vehicle in
                VehicleDetailSheet(vehicle: vehicle, modelContext: modelContext)
            }
        }
    }
    
    private var typeFilter: some View {
        Section(header: Text("Filter")) {
            Picker("Vehicle Type", selection: $viewModel.selectedType) {
                Text("All Types").tag(nil as VehicleType?)
                ForEach(VehicleType.allCases, id: \.self) { type in
                    type.labelView.tag(type as VehicleType?)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }
    
    @ViewBuilder
    private var vehiclesList: some View {
        if !unsetVehicles.isEmpty {
            Section("Needs Configuration / Unset") {
                ForEach(unsetVehicles) { vehicle in
                    vehicleRow(vehicle)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteVehicle(unsetVehicles[index])
                    }
                }
            }
        }
        
        if !validVehicles.isEmpty {
            Section("Vehicles") {
                ForEach(validVehicles) { vehicle in
                    vehicleRow(vehicle)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteVehicle(validVehicles[index])
                    }
                }
            }
        } else if unsetVehicles.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
    
    @ViewBuilder
    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        Button(action: {
            vehicleToEdit = vehicle
        }) {
            VehicleRowView(vehicle: vehicle) { v in
                withAnimation(.snappy) {
                    viewModel.updateModel(v) { concreteVehicle in
                        concreteVehicle.cache.toggle()
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Vehicle.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            let vehicle1 = Vehicle(rid: 101, name: "Le Viano", type: .car, cityRid: 12)
            let vehicle2 = Vehicle(rid: 102, name: "Le BTwin", type: .bike)
            let vehicle3 = Vehicle(rid: 104, name: "La Defender", type: .car)
            
            
            let context = container.mainContext
            
            context.insert(vehicle1)
            context.insert(vehicle2)
            context.insert(vehicle3)
            
            return container
        } catch {
            fatalError("Failed to create model container for preview: \(error.localizedDescription)")
        }
    }()
    
    NavigationStack {
        VehiclesPage()
            .modelContainer(container)
    }
}
