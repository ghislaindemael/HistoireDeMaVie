//
//  TripsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.06.2025.
//

import SwiftUI
import SwiftData

struct TripsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TripsPageViewModel()
    
    @Query(sort: [SortDescriptor<Trip>(\.time_start, order: .reverse)]) private var localCacheTrips: [Trip]
    
    @State private var tripToEdit: Trip?
    
    public init() {}
    
    
    var body: some View {
        NavigationStack {
            tripListView
                .navigationTitle("Trips")
                .toolbar { toolbarContent }
                .task(id: viewModel.selectedDate) {
                    await viewModel.loadData()
                }
                .onChange(of: localCacheTrips) {
                    viewModel.localCacheDidChange(localCacheTrips)
                }
                .onAppear {
                    viewModel.setup(modelContext: modelContext)
                }
                .sheet(item: $tripToEdit, onDismiss: {
                    Task { await viewModel.syncChanges() }
                }) { trip in
                    TripDetailSheet(trip: trip)
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
        }
    }
    
    // MARK: - View Components
    
    /// A computed property for the main view content to help the compiler.
    private var tripListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            List {
                ForEach(viewModel.displayTrips) { trip in
                    VStack(spacing: 8) {
                        TripRowView(displayTrip: trip)
                        if trip.time_end == nil {
                            Button("End Trip Now") {
                                if let modelTrip = viewModel.prepareForEdit(trip: trip) {
                                    modelTrip.time_end = .now
                                    try? modelContext.save()
                                    Task {
                                        await viewModel.syncChanges()
                                    }
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .buttonStyle(.plain)
                        }
                    }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                tripToEdit = viewModel.prepareForEdit(trip: trip)
                            }
                    )
                    .onLongPressGesture {
                        tripToEdit = viewModel.prepareForEdit(trip: trip)
                    }
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                Task { await viewModel.loadData() }
            }) {
                Image(systemName: "icloud.and.arrow.down")
                Text("Refresh")
            }
            .accessibilityLabel("Reload trips")
        }
        
        if viewModel.hasLocalTrips {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    Task { await viewModel.syncChanges() }
                }) {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Save")
                }
                .accessibilityLabel("Sync changes")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                viewModel.createNewTripInCache()
            }) {
                Image(systemName: "plus")
                Text("New trip")
            }
        }
    }
}
#Preview {
    let container: ModelContainer = {
        let schema = Schema([
            Trip.self,
            Vehicle.self,
            VehicleType.self,
            Place.self,
            City.self,
            Country.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            
            let carType = VehicleType(id: 1, slug: "car", name: "Car", icon: "car.fill")
            let car = Vehicle(id: 101, name: "My Car", favourite: true, type: carType.id)
            context.insert(carType)
            context.insert(car)
            
            let switzerland = Country(id: 1, slug: "ch", name: "Switzerland")
            let geneva = City(id: 10, slug: "geneva", name: "Geneva", rank: 1, country_id: 1)
            let cern = Place(id: 100, name: "CERN", city_id: 10)
            let airport = Place(id: 101, name: "Geneva Airport", city_id: 10)
            context.insert(switzerland)
            context.insert(geneva)
            context.insert(cern)
            context.insert(airport)
            
            
            let trip1 = Trip(
                id: 201,
                time_start: .now.addingTimeInterval(-10800),
                time_end: .now.addingTimeInterval(-7200),
                vehicle_id: car.id,
                place_start_id: cern.id,
                place_end_id: airport.id,
            )
            
            let trip2 = Trip(
                id: 202,
                time_start: .now.addingTimeInterval(-1800),
                time_end: nil,
                vehicle_id: car.id,
                place_start_id: airport.id,
            )
            
            let trip3 = Trip(
                id: -1,
                time_start: .now.addingTimeInterval(-600),
                time_end: nil,
            )
            
            context.insert(trip1)
            context.insert(trip2)
            context.insert(trip3)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    return TripsPage().modelContainer(container)
}
