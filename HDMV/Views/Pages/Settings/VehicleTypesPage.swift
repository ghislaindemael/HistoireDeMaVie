//
//  VehicleTypesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//

import SwiftUI
import SwiftData

struct VehicleTypesPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel = VehicleTypesPageViewModel()
    
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(viewModel.vehicleTypes) { type in
                        HStack {
                            Text("\(type.label)")
                                .tag(type as VehicleType?)
                            Spacer()
                            
                            Toggle("Cache", isOn: Binding(
                                get: { type.cache },
                                set: { _ in
                                    viewModel.toggleCache(for: type)
                                }
                            ))
                            .labelsHidden()
                        }

                    }
                }
            }
            .navigationTitle("Vehicle Types")
            .standardConfigPageToolbar(
                refreshAction: viewModel.refreshDataFromServer,
                cacheAction: viewModel.cacheVehicleTypes,
                isShowingAddSheet: $isShowingAddSheet
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext, settings: settings)
            }
            .sheet(isPresented: $isShowingAddSheet) {
                NewVehicleTypeSheet(viewModel: viewModel)
            }
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
