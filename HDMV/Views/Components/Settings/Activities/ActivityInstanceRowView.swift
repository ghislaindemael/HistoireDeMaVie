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
    
    let instance: ActivityInstance
    let selectedDate: Date
    
    init(
        instance: ActivityInstance,
        selectedDate: Date,
    ) {
        self.instance = instance
        self.selectedDate = selectedDate
    }
    
    
    var body: some View {
        VStack {
            basicsSection
            detailsSection
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondaryBackgroundColor)
        )
        
    }
    
    @ViewBuilder
    private var basicsSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                HStack() {
                    IconView(
                        iconString: instance.activity?.icon ?? "questionmark.circle",
                        size: 30,
                        tint: instance.activity == nil ? .red : .primary,
                    )
                    
                    VStack(alignment: .leading) {
                        Text(instance.activity?.name ?? "Unassigned")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(instance.activity != nil ? Color.primary : Color.red)
                        HStack(spacing: 4) {
                            if let startDateString = displayDateIfNeeded(for: instance.timeStart, comparedTo: selectedDate) {
                                Text("\(startDateString) ")
                            }
                            Text(instance.timeStart, style: .time)
                            
                            Image(systemName: "arrow.right")
                            
                            if let timeEnd = instance.timeEnd {
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
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .foregroundColor(Color.primary)
                    .font(.body)
            }
            
            if instance.percentage != 100 {
                GradientPercentageBarView(percentage: Double(instance.percentage))
                    .frame(height: 10)
            }
            if instance.activity?.can(.log_food) == true {
                mealContentText
            }
            if instance.activity?.shouldShowPlaceLink(settings: settings) == true {
                linkedPlaceView
            }
            
        }
    }
    
    @ViewBuilder
    private var mealContentText: some View {
        
        let displayText = instance.decodedActivityDetails?.meal?.displayText ?? "Meal not logged."
        let isMissingRequiredDetails = instance.activity?.must(.log_food) ?? false && instance.decodedActivityDetails?.meal == nil
        
        Text(displayText)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .foregroundColor(isMissingRequiredDetails ? .red : .primary)
            .fontWeight(isMissingRequiredDetails ? .bold : .regular)
            .font(.body)
    }
    
    @ViewBuilder
    private var linkedPlaceView: some View {
        
        let placeId = instance.decodedActivityDetails?.place?.placeId
        let color = instance.activity?.placeUnsetColor(settings: settings, placeId: placeId)
        let weight = instance.activity?.placeUnsetWeight(placeId: placeId)

        PlaceDisplayView(
            placeRid: placeId,
            showMapPin: true,
            color: color,
            fontWeight: weight
        )
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
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
                selectedDate: .now
            )
        }
    }
}



struct PreviewWrapperView: View {
    @Query private var instances: [ActivityInstance]
    @Query private var activities: [Activity]
    @Query private var trips: [Trip]
    @Query private var vehicles: [Vehicle]
    @Query private var places: [Place]
    
    var body: some View {
        List {
            if let inProgress = instances.first(where: { $0.rid == 1 }) {
                InstanceSection(
                    title: "In Progress",
                    instance: inProgress
                )
            }
            if let completed = instances.first(where: { $0.rid == 2 }) {
                InstanceSection(
                    title: "Completed",
                    instance: completed,
                )
            }
            if let unassigned = instances.first(where: { $0.rid == 3 }) {
                InstanceSection(
                    title: "Unassigned",
                    instance: unassigned,
                )
            }
            if let trip = instances.first(where: { $0.rid == 4 }) {
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
    let container = try! ModelContainer(for: Activity.self, ActivityInstance.self, Trip.self, Vehicle.self, Place.self, configurations: config)
    
    NavigationStack {
        PreviewWrapperView()
    }
    .modelContainer(container)
    .onAppear {
        let context = container.mainContext
        
        
        let place1 = Place(rid: 101, name: "HQ Office", cityRid: 1)
        let place2 = Place(rid: 102, name: "Client Site A", cityRid: 2)
        let place3 = Place(rid: 103, name: "Warehouse", cityRid: 3)
        
        let vehicle1 = Vehicle(
            rid: 201,
            name: "Van-01",
            type: .car,
        )
        
        let workActivity = Activity(
            rid: 1,
            name: "Work",
            slug: "",
            icon: "shippingbox.fill"
        )
        let lunchActivity = Activity(
            rid: 2,
            name: "Lunch Break",
            slug: "",
            icon: "fork.knife"
        )
        
        let travelActivity = Activity(
            rid: 3,
            name: "Travel",
            slug: "travel",
            icon: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            allowedCapabilities: [.create_trips]
        )
        
        let inProgressInstance = ActivityInstance(
            rid: 1,
            timeStart: .now.addingTimeInterval(-3600),
            timeEnd: nil,
            percentage: 75,
            activityRid: workActivity.rid,
            syncStatus: .syncing
        )
        
        
        let completedInstance = ActivityInstance(
            rid: 2,
            timeStart: .now.addingTimeInterval(-10800),
            timeEnd: .now.addingTimeInterval(-7200),
            percentage: 100,
            activityRid: lunchActivity.rid,
            syncStatus: .synced
        )
        
        let unassignedInstance = ActivityInstance(
            rid: 3,
            timeStart: .now,
            timeEnd: nil,
            percentage: 75,
            activityRid: nil,
            syncStatus: .local
        )
        
        let travelInstance = ActivityInstance(
            rid: 4,
            timeStart: .now,
            timeEnd: nil,
            percentage: 50,
            activityRid: travelActivity.rid,
            syncStatus: .local
        )
        
        let completedTrip = Trip(
            rid: 301,
            timeStart: .now.addingTimeInterval(-3500),
            timeEnd: .now.addingTimeInterval(-1800),
            parentInstance: travelInstance,
            placeStart: place1,
            placeEnd: place2,
            vehicle: nil,
            syncStatus: .synced
        )
        
        let inProgressTrip = Trip(
            rid: 302,
            timeStart: .now.addingTimeInterval(-900),
            timeEnd: nil,
            parentInstance: inProgressInstance,
            placeStart: place2,
            placeEnd: nil,
            vehicle: nil,
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
        [completedTrip, inProgressTrip].forEach { context.insert($0) }
        
    }
}
