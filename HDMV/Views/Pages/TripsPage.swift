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
    @Query private var vehicleTypes: [VehicleType]
    @Query private var vehicles: [Vehicle]
    @Query private var places: [Place]
    
    @State private var tripToEdit: TripDisplayModel?
    @State private var endingTripId: Int?
    
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
                    TripDetailSheet(trip: trip) { savedTrip in
                        viewModel.saveTrip(savedTrip)
                    }
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
                    viewForRow(for: trip)
                }
            }
        }
    }
    
    private func viewForRow(for trip: TripDisplayModel) -> some View {
        VStack(spacing: 8) {
            TripRowView(
                displayTrip: trip,
                vehicleTypes: vehicleTypes,
                vehicles: vehicles,
                places: places
            )
            .padding(.top, trip.time_end == nil ? 6 : 0)
            .animation(nil, value: endingTripId)
            .zIndex(1)
            
            
            endTripButton(for: trip)
                .frame(maxHeight: trip.time_end == nil ? .infinity : 0)
                .opacity(trip.time_end == nil ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: trip.time_end)
            
                .scaleEffect(endingTripId == trip.id ? 0.01 : 1.0)
            
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    tripToEdit = trip
                }
        )
        .onLongPressGesture {
            tripToEdit = trip
        }
    }
    
    @ViewBuilder
    private func endTripButton(for trip: TripDisplayModel) -> some View {
        
            Button("End Trip Now") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.endingTripId = trip.id
                } completion: {
                    guard let tripToEnd = viewModel.displayTrips.first(where: { $0.id == trip.id }) else { return }
                    
                    let mutableTrip = tripToEnd.asEditableTrip()
                    mutableTrip.time_end = .now
                    viewModel.saveTrip(mutableTrip)
                    
                    Task {
                        await viewModel.syncChanges()
                    }
                    self.endingTripId = nil
                    
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
                time_start: .now.addingTimeInterval(-1000),
                time_end: .now.addingTimeInterval(-720),
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

extension TripDisplayModel {
    func asEditableTrip() -> Trip {
        return Trip(
            id: self.id,
            time_start: self.time_start,
            time_end: self.time_end,
            vehicle_id: self.vehicle_id,
            place_start_id: self.place_start_id,
            place_end_id: self.place_end_id
        )
    }
}
