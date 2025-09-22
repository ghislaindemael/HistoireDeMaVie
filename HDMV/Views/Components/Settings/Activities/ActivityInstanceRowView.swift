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
    
    let instance: ActivityInstance
    let activity: Activity?
    let tripLegs: [TripLeg]
    let tripLegsVehicles: [Vehicle]
    let tripLegsPlaces: [Place]
    let selectedDate: Date
    let onStartTripLeg: (Int) -> Void
    let onEditTripLeg: (TripLeg) -> Void
    let onEndTripLeg: (TripLeg) -> Void
    let onStartInteraction: (Int) -> Void
    let onEditInteraction: (PersonInteraction) -> Void
    let onEndInteraction: (PersonInteraction) -> Void
    
    var hasActiveLeg: Bool {
        tripLegs.contains { $0.time_end == nil }
    }
    
    var body: some View {
        VStack {
            
            basicsSection
            detailsSection
            
            
            if let act = activity,
               instance.time_end == nil,
               act.can(.create_trip_legs),
               act.can(.create_interactions)
            {
                HStack {
                    if act.can(.create_trip_legs) {
                        StartItemButton(title: "Start trip leg") {
                            onStartTripLeg(instance.id)
                        }
                        .disabled(hasActiveLeg)
                    }
                    if act.can(.create_interactions) {
                        StartItemButton(title: "Start interaction") {
                            onStartInteraction(instance.id)
                        }
                    }
                }
            }
            
            if activity?.can(.create_trip_legs) == true {
                tripLegsSection
                    .padding(.leading, 30)
            }
            
            if activity?.can(.create_interactions) == true {
                
            }
        }
        
    }
    
    
    @ViewBuilder
    private var basicsSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                HStack() {
                    IconView(
                        iconString: activity?.icon ?? "x.circle",
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
            HStack(spacing: 2) {
                if !instance.isValid() {
                    IconView(
                        iconString: "exclamationmark.triangle.fill",
                        tint: .yellow
                    )
                }
                SyncStatusIndicator(status: instance.syncStatus)
            }
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
        VStack(alignment: .leading, spacing: 10) {
            ForEach(tripLegs) { leg in
                Button(action: { onEditTripLeg(leg) }) {
                    VStack{
                        TripLegRowView(
                            tripLeg: leg,
                            vehicle: tripLegsVehicles.first(where: {$0.id == leg.vehicle_id}),
                            places: tripLegsPlaces
                        )
                        if leg.time_end == nil {
                            EndItemButton(title: "End Trip Leg") {
                                onEndTripLeg(leg)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
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

struct PreviewWrapperView: View {
    @Query private var instances: [ActivityInstance]
    @Query private var activities: [Activity]
    @Query private var tripLegs: [TripLeg]
    @Query private var vehicles: [Vehicle]
    @Query private var places: [Place]
    
    var body: some View {
        List {
            if let inProgressInstance = instances.first(where: { $0.id == 1 }) {
                Section("In Progress") {
                    ActivityInstanceRowView(
                        instance: inProgressInstance,
                        activity: activities.first(where: { $0.id == inProgressInstance.activity_id }),
                        tripLegs: tripLegs.filter { $0.parent_id == inProgressInstance.id },
                        tripLegsVehicles: vehicles,
                        tripLegsPlaces: places,
                        selectedDate: .now,
                        onStartTripLeg: { _ in }, onEditTripLeg: { _ in }, onEndTripLeg: { _ in },
                        onStartInteraction: { _ in }, onEditInteraction: { _ in }, onEndInteraction: { _ in }
                    )
                }
            }
            
            if let completedInstance = instances.first(where: { $0.id == 2 }) {
                Section("Completed") {
                    ActivityInstanceRowView(
                        instance: completedInstance,
                        activity: activities.first(where: { $0.id == completedInstance.activity_id }),
                        tripLegs: [],
                        tripLegsVehicles: [],
                        tripLegsPlaces: [],
                        selectedDate: .now,
                        onStartTripLeg: { _ in }, onEditTripLeg: { _ in }, onEndTripLeg: { _ in },
                        onStartInteraction: { _ in }, onEditInteraction: { _ in }, onEndInteraction: { _ in }
                    )
                }
            }
            
            if let unassignedInstance = instances.first(where: { $0.id == 3 }) {
                Section("Unassigned") {
                    ActivityInstanceRowView(
                        instance: unassignedInstance,
                        activity: nil,
                        tripLegs: [],
                        tripLegsVehicles: [],
                        tripLegsPlaces: [],
                        selectedDate: .now,
                        onStartTripLeg: { _ in }, onEditTripLeg: { _ in }, onEndTripLeg: { _ in },
                        onStartInteraction: { _ in }, onEditInteraction: { _ in }, onEndInteraction: { _ in }
                    )
                }
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
        
        let vehicle1 = Vehicle(id: 201, name: "Van-01", type: 2)
        
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
        
        let completedLeg = TripLeg(
            id: 301,
            parent_id: inProgressInstance.id,
            time_start: .now.addingTimeInterval(-3500),
            time_end: .now.addingTimeInterval(-1800),
            vehicle_id: vehicle1.id,
            place_start_id: place1.id,
            place_end_id: place2.id,
            syncStatus: .synced
        )
        
        let inProgressLeg = TripLeg(
            id: 302,
            parent_id: inProgressInstance.id,
            time_start: .now.addingTimeInterval(-900),
            time_end: nil,
            vehicle_id: vehicle1.id,
            place_start_id: place2.id,
            place_end_id: nil,
            syncStatus: .syncing
        )
        
        let unassignedInstance = ActivityInstance(
            id: 3,
            time_start: .now,
            time_end: nil,
            activity_id: nil,
            percentage: nil,
            syncStatus: .local
        )
        
        [place1, place2, place3].forEach { context.insert($0) }
        context.insert(vehicle1)
        [workActivity, lunchActivity].forEach { context.insert($0) }
        [inProgressInstance, completedInstance, unassignedInstance].forEach { context.insert($0) }
        [completedLeg, inProgressLeg].forEach { context.insert($0) }
        
    }
}
