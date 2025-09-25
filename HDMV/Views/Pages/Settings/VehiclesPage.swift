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
    
    @State private var isShowingCreateSheet = false
    @State private var selectedVehicleType: VehicleType?
    
    init() {}
    
    private var filteredVehicles: [Vehicle] {
        guard let selectedType = selectedVehicleType else { return viewModel.vehicles }
        return viewModel.vehicles.filter { $0.type == selectedType.id }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                vehicleFilterSection
                vehicleListSection
            }
            .navigationTitle("Vehicles")
            .standardConfigPageToolbar(
                refreshAction: viewModel.fetchFromServer,
                cacheAction: viewModel.cacheVehicles,
                isShowingAddSheet: $isShowingCreateSheet
            )
            .task {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                NewVehicleSheet(viewModel: viewModel)
            }
            .syncingOverlay(viewModel.isLoading)
        }
    }
    
    private var vehicleFilterSection: some View {
        Section(header: Text("Filter")) {
            Picker("Vehicle Type", selection: $selectedVehicleType) {
                Text("All Types").tag(nil as VehicleType?)
                ForEach(viewModel.vehicleTypes) { type in
                    Text(type.label).tag(type as VehicleType?)
                }
            }
        }
    }
    
    private var vehicleListSection: some View {
        Section(header: Text(selectedVehicleType?.name ?? "All Vehicles")) {
            ForEach(filteredVehicles) { vehicle in
                VehicleRow(
                    vehicle: vehicle,
                    onCacheToggle: {
                        viewModel.toggleCache(for: vehicle)
                    }
                )
            }
        }
    }


    
    private func deleteVehicles(at offsets: IndexSet) {
        for index in offsets {
            let vehicle = filteredVehicles[index]
            viewModel.delete(vehicle: vehicle)
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Vehicle.self, VehicleType.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            let carType = VehicleType(id: 1, slug: "car", name: "Car", icon: "car.fill")
            let bikeType = VehicleType(id: 2, slug: "bicycle", name: "Bicycle", icon: "bicycle")
            
            let vehicle1 = Vehicle(id: 101, name: "Le Viano", type: carType.id, city_id: 12)
            let vehicle2 = Vehicle(id: 102, name: "Le BTwin", type: bikeType.id)
            let vehicle3 = Vehicle(id: 104, name: "La Defender", type: carType.id)
            
            
            let context = container.mainContext
            context.insert(carType)
            context.insert(bikeType)
            
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
