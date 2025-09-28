//
//  ActivityInstanceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct ActivityInstanceRowView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = SettingsStore.shared
    
    @Query private var activities: [Activity]
    
    let instance: ActivityInstance
    let tripLegs: [TripLeg]
    var interactions: [PersonInteraction]
    let selectedDate: Date
    let onStartTripLeg: (Int) -> Void
    let onEditTripLeg: (TripLeg) -> Void
    let onEndTripLeg: (TripLeg) -> Void
    let onStartInteraction: (Int) -> Void
    let onEditInteraction: (PersonInteraction) -> Void
    let onEndInteraction: (PersonInteraction) -> Void
    
    private var activity: Activity? {
        activities.first
    }
    
    init(
        instance: ActivityInstance,
        tripLegs: [TripLeg],
        interactions: [PersonInteraction],
        selectedDate: Date,
        onStartTripLeg: @escaping (Int) -> Void,
        onEditTripLeg: @escaping (TripLeg) -> Void,
        onEndTripLeg: @escaping (TripLeg) -> Void,
        onStartInteraction: @escaping (Int) -> Void,
        onEditInteraction: @escaping (PersonInteraction) -> Void,
        onEndInteraction: @escaping (PersonInteraction) -> Void
    ) {
        self.instance = instance
        if let id = instance.activity_id {
            _activities = Query(filter: #Predicate { $0.id == id })
        } else {
            _activities = Query(filter: #Predicate { _ in false })
        }
                
        self.tripLegs = tripLegs
        self.interactions = interactions
        self.selectedDate = selectedDate
        self.onStartTripLeg = onStartTripLeg
        self.onEditTripLeg = onEditTripLeg
        self.onEndTripLeg = onEndTripLeg
        self.onStartInteraction = onStartInteraction
        self.onEditInteraction = onEditInteraction
        self.onEndInteraction = onEndInteraction
    }
    
    var hasActiveLeg: Bool {
        tripLegs.contains { $0.time_end == nil }
    }
    
    var body: some View {
        VStack {
            
            basicsSection
            detailsSection
                        
            if activity?.can(.create_trip_legs) == true {
                tripLegsSection
            }
            
            if activity?.can(.create_interactions) == true {
                peopleInteractionsSection
            }
        }
        
    }
    
    
    @ViewBuilder
    private var basicsSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                HStack() {
                    IconView(
                        iconString: activity?.icon ?? "questionmark.circle",
                        size: 30,
                        tint: instance.activity_id == nil ? .red : .primary,
                    )
                    
                    VStack(alignment: .leading) {
                        Text(activity?.name ?? "Unassigned")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(activity != nil ? Color.primary : Color.red)
                        HStack(spacing: 4) {
                            if let startDateString = displayDateIfNeeded(for: instance.time_start, comparedTo: selectedDate) {
                                Text("\(startDateString) ")
                            }
                            Text(instance.time_start, style: .time)
                            
                            Image(systemName: "arrow.right")
                            
                            if let timeEnd = instance.time_end {
                                if let endDateString = displayDateIfNeeded(for: timeEnd, comparedTo: selectedDate) {
                                    Text("\(endDateString) ")
                                }
                                Text(timeEnd, style: .time)
                            } else {
                                Text("—").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                        
                    }
                    Spacer()
                    
                }
                
            }
            .padding(.vertical, 4)
            
            SyncStatusIndicator(status: instance.syncStatus)
                .padding([.top, .trailing], 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack {
            
            if let details = instance.details, !details.isEmpty {
                Text(details)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .foregroundColor(Color.primary)
                    .font(.body)
            }
            
            if let percentage = instance.percentage {
                GradientPercentageBarView(percentage: Double(percentage))
                    .frame(height: 8)
                    .padding(.leading, 4)
            }
            if activity?.can(.log_food) == true {
                mealContentText
            }
            
        }
    }
    
    @ViewBuilder
    private var tripLegsSection: some View {
        VStack(alignment: .leading) {
            ForEach(tripLegs) { leg in
                Button(action: { onEditTripLeg(leg) }) {
                    TripLegRowView(
                        tripLeg: leg,
                        isSmall: true,
                        onEnd: {
                            onEndTripLeg(leg)
                        },
                    )
                }
                .buttonStyle(.plain)
            }
            if (instance.time_end == nil && !hasActiveLeg) || settings.planningMode {
                StartItemButton(title: "Start trip leg") {
                    onStartTripLeg(instance.id)
                }
            }
        }.padding(0)
    }
    
    @ViewBuilder
    private var peopleInteractionsSection: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            ForEach(interactions) { interaction in
                Button(action: { onEditInteraction(interaction) }) {
                    PersonInteractionRowView(
                        interaction: interaction,
                        onEnd: {
                            onEndInteraction(interaction)
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            if instance.time_end == nil || settings.planningMode {
                StartItemButton(title: "Start interaction") {
                    onStartInteraction(instance.id)
                }
            }
            
        }
    }

    
    @ViewBuilder
    private var mealContentText: some View {
        
        let displayText = instance.decodedActivityDetails?.meal?.displayText ?? "Meal not logged."
        let isMissingRequiredDetails = activity!.must(.log_food) && instance.decodedActivityDetails?.meal == nil

        Text(displayText)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .foregroundColor(isMissingRequiredDetails ? .red : .primary)
            .fontWeight(isMissingRequiredDetails ? .bold : .regular)
            .font(.body)
    }
    
    private func displayDateIfNeeded(for date: Date, comparedTo selectedDate: Date) -> String? {
        let calendar = Calendar.current
        if !calendar.isDate(date, inSameDayAs: selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
        return nil
    }
    
}

// MARK: - Preview

struct InstanceSection: View {
    let title: String
    let instance: ActivityInstance
    
    @Environment(\.modelContext) private var modelContext
    
    // Fetch trip legs for this instance
    private var tripLegs: [TripLeg] {
        let instanceId = instance.id
        let descriptor = FetchDescriptor<TripLeg>(
            predicate: #Predicate { $0.parent_id == instanceId },
            sortBy: [SortDescriptor(\.time_start)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }


    private var vehicles: [Vehicle] {
        let vehicleIds = tripLegs.compactMap { $0.vehicle_id }
        guard !vehicleIds.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<Vehicle>(
            predicate: #Predicate { vehicleIds.contains($0.id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private var places: [Place] {
        let placeIds = tripLegs
            .flatMap { [$0.place_start_id, $0.place_end_id] }
            .compactMap { $0 }
        guard !placeIds.isEmpty else { return [] }
        
        let descriptor = FetchDescriptor<Place>(
            predicate: #Predicate { placeIds.contains($0.id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private var interactions: [PersonInteraction] {
        let instanceId = instance.id
        let descriptor = FetchDescriptor<PersonInteraction>(
            predicate: #Predicate { $0.parent_activity_id == instanceId },
            sortBy: [SortDescriptor(\.time_start)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    
    init(
        title: String,
        instance: ActivityInstance,
    ) {
        self.title = title
        self.instance = instance
    }
    
    var body: some View {
        Section(title) {
            ActivityInstanceRowView(
                instance: instance,
                tripLegs: tripLegs,
                interactions: interactions,
                selectedDate: .now,
                onStartTripLeg: { _ in },
                onEditTripLeg: { _ in },
                onEndTripLeg: { _ in },
                onStartInteraction: { _ in },
                onEditInteraction: { _ in },
                onEndInteraction: { _ in }
            )
        }
    }
}



struct PreviewWrapperView: View {
    @Query private var instances: [ActivityInstance]
    @Query private var activities: [Activity]
    @Query private var tripLegs: [TripLeg]
    @Query private var vehicles: [Vehicle]
    @Query private var places: [Place]
    
    var body: some View {
        List {
            if let inProgress = instances.first(where: { $0.id == 1 }) {
                InstanceSection(
                    title: "In Progress",
                    instance: inProgress
                )
            }
            if let completed = instances.first(where: { $0.id == 2 }) {
                InstanceSection(
                    title: "Completed",
                    instance: completed,
                )
            }
            if let unassigned = instances.first(where: { $0.id == 3 }) {
                InstanceSection(
                    title: "Unassigned",
                    instance: unassigned,
                )
            }
            if let trip = instances.first(where: { $0.id == 4 }) {
                InstanceSection(
                    title: "Trip",
                    instance: trip,
                )
            }
            
        }
        .navigationTitle("Activity Instances")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Activity.self, ActivityInstance.self, TripLeg.self, Vehicle.self, Place.self, configurations: config)
    
    NavigationStack {
        PreviewWrapperView()
    }
    .modelContainer(container)
    .onAppear {
        let context = container.mainContext
        
        
        let place1 = Place(id: 101, name: "HQ Office", city_id: 1, city_name: "Geneva")
        let place2 = Place(id: 102, name: "Client Site A", city_id: 2, city_name: "Lausanne")
        let place3 = Place(id: 103, name: "Warehouse", city_id: 3, city_name: "Zurich")
        
        let vehicle1 = Vehicle(
            id: 201,
            name: "Van-01",
            type: .car,
            label: "🚙 Viano"
        )
        
        let workActivity = Activity(
            id: 1,
            name: "Work",
            slug: "",
            icon: "shippingbox.fill"
        )
        let lunchActivity = Activity(
            id: 2,
            name: "Lunch Break",
            slug: "",
            icon: "fork.knife"
        )
        
        let travelActivity = Activity(
            id: 3,
            name: "Travel",
            slug: "travel",
            icon: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            allowedCapabilities: [.create_trip_legs]
        )
        
        let inProgressInstance = ActivityInstance(
            id: 1,
            time_start: .now.addingTimeInterval(-3600),
            time_end: nil,
            activity_id: workActivity.id,
            percentage: 75,
            syncStatus: .syncing
        )
        
        
        let completedInstance = ActivityInstance(
            id: 2,
            time_start: .now.addingTimeInterval(-10800),
            time_end: .now.addingTimeInterval(-7200),
            activity_id: lunchActivity.id,
            percentage: 100,
            syncStatus: .synced
        )
        
        let unassignedInstance = ActivityInstance(
            id: 3,
            time_start: .now,
            time_end: nil,
            activity_id: nil,
            percentage: nil,
            syncStatus: .local
        )
        
        let travelInstance = ActivityInstance(
            id: 4,
            time_start: .now,
            time_end: nil,
            activity_id: travelActivity.id,
            percentage: 50,
            syncStatus: .local
        )
        
        let completedLeg = TripLeg(
            id: 301,
            parent_id: travelInstance.id,
            time_start: .now.addingTimeInterval(-3500),
            time_end: .now.addingTimeInterval(-1800),
            vehicle_id: nil,
            place_start_id: place1.id,
            place_end_id: place2.id,
            syncStatus: .synced
        )
        
        let inProgressLeg = TripLeg(
            id: 302,
            parent_id: inProgressInstance.id,
            time_start: .now.addingTimeInterval(-900),
            time_end: nil,
            vehicle_id: nil,
            place_start_id: place2.id,
            place_end_id: nil,
            syncStatus: .syncing
        )
        
        
        [place1, place2, place3].forEach { context.insert($0) }
        context.insert(vehicle1)
        [
            workActivity,
            lunchActivity,
            travelActivity
        ].forEach { context.insert($0) }
        [
            inProgressInstance,
            completedInstance,
            unassignedInstance,
            travelInstance
        ].forEach { context.insert($0) }
        [completedLeg, inProgressLeg].forEach { context.insert($0) }
        
    }
}
