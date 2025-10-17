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
    
    var body: some View {
        NavigationStack {
            Form {
                typeFilter
                vehiclesList
            }
            .navigationTitle("Vehicles")
            .logPageToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                singleTapAction: { viewModel.createVehicle() },
                longPressAction: {}
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
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
                    Text(type.label).tag(type as VehicleType?)
                }
            }
        }
    }
    
    @ViewBuilder
    private var vehiclesList: some View {
        Section("Vehicles") {
            ForEach(viewModel.filteredVehicles) { vehicle in
                Button(action: {
                    vehicleToEdit = vehicle
                }) {
                    VehicleRowView(vehicle: vehicle)
                }
                .buttonStyle(.plain)
            }
        }
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
