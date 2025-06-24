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
    @StateObject private var viewModel = VehiclesPageViewModel()
    
    @State private var isShowingCreateSheet = false
    @State private var selectedVehicleType: VehicleType?
    
    init() {}
    
    private var filteredVehicles: [Vehicle] {
        guard let selectedType = selectedVehicleType else { return viewModel.vehicles }
        return viewModel.vehicles.filter { $0.type == selectedType.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Filter")) {
                        Picker("Vehicle Type", selection: $selectedVehicleType) {
                            Text("All Types").tag(nil as VehicleType?)
                            ForEach(viewModel.vehicleTypes) { type in
                                Text(type.icon + " " + type.name).tag(type as VehicleType?)
                            }
                        }
                    }
                    
                    Section(header: Text(selectedVehicleType?.name ?? "All Vehicles")) {
                        ForEach(filteredVehicles) { vehicle in
                            VehicleRow(
                                vehicle: vehicle,
                                label: viewModel.vehicleLabel(for: vehicle),
                                onToggleFavorite: { viewModel.toggleFavorite(for: vehicle) }
                            )
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task { await viewModel.refreshDataFromServer() }
                    }) {
                        Image(systemName: "arrow.trianglehead.counterclockwise.icloud.fill")
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
                NewVehicleSheet(viewModel: viewModel)
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
            
            let vehicle1 = Vehicle(id: 101, name: "Le Viano", favourite: true, type: carType.id, city_id: 12)
            let vehicle2 = Vehicle(id: 102, name: "Le BTwin", favourite: false, type: bikeType.id)
            let vehicle3 = Vehicle(id: 104, name: "La Defender", favourite: false, type: carType.id)
            
            
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
    
    return NavigationStack {
        VehiclesPage()
            .modelContainer(container)
    }
}
