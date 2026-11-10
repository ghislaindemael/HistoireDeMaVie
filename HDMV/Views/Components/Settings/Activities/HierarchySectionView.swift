import SwiftUI
import SwiftData

struct HierarchySectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    let model: any LogModel
    let hasParent: Bool
    var parentInstance: ActivityInstance? = nil
    var parentTrip: Trip? = nil
    var onSelectParent: ((any ParentModel)?) -> Void = { _ in }
    let onRemoveFromParent: () -> Void
    
    @State private var justCreatedTrip = false
    @State private var justCreatedInstance = false
    
    var body: some View {
        Section("Parent") {
            // 1. Current Parent Inspector
            if let instance = parentInstance {
                HStack(spacing: 8) {
                    IconView(iconString: instance.activity?.icon ?? "flowchart.fill", size: 22, tint: .blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(instance.activity?.name ?? "Activity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(instance.timeStart, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Activity")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondaryBackground)
                        .cornerRadius(4)
                }
            } else if let trip = parentTrip {
                HStack(spacing: 8) {
                    IconView(iconString: trip.vehicle?.icon ?? "car.fill", size: 22, tint: .indigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name ?? trip.vehicle?.name ?? "Trip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(trip.timeStart, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Trip")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondaryBackground)
                        .cornerRadius(4)
                }
            } else {
                HStack {
                    Text("No Parent")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            // 2. Change / Assign Parent Link
            NavigationLink {
                ParentSelectionListView(
                    currentDate: model.timeStart,
                    currentParentId: parentInstance?.persistentModelID ?? parentTrip?.persistentModelID,
                    onSelectParent: { newParent in
                        onSelectParent(newParent)
                    }
                )
            } label: {
                HStack {
                    Label(hasParent ? "Change Parent" : "Assign Parent", systemImage: "arrow.triangle.branch")
                        .foregroundColor(.blue)
                }
            }
            
            // 3. Clear Parent
            if hasParent {
                Button("Remove from Parent", role: .destructive) {
                    onRemoveFromParent()
                }
            }
        }
        
        // 4. If the model is itself a ParentModel, show child creation actions
        if let parentModel = model as? any ParentModel {
            Section("Hierarchy Children") {
                Button(action: {
                    withAnimation {
                        createChildTrip(parent: parentModel)
                        justCreatedTrip = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { justCreatedTrip = false }
                    }
                }) {
                    HStack {
                        Text("Create Child Trip")
                        if justCreatedTrip {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                Button(action: {
                    withAnimation {
                        createChildInstance(parent: parentModel)
                        justCreatedInstance = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { justCreatedInstance = false }
                    }
                }) {
                    HStack {
                        Text("Create Child Instance")
                        if justCreatedInstance {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
    
    private func createChildInstance(parent: any ParentModel) {
        ActivityInstance.createChild(in: modelContext, parent: parent, filterDate: parent.timeStart)
    }
    
    private func createChildTrip(parent: any ParentModel) {
        Trip.create(in: modelContext, parent: parent, filterDate: parent.timeStart)
    }
}

// MARK: - Parent Selection List

struct ParentSelectionListView: View {
    let currentDate: Date
    let currentParentId: PersistentIdentifier?
    let onSelectParent: (any ParentModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var filterDate: Date
    
    init(currentDate: Date, currentParentId: PersistentIdentifier? = nil, onSelectParent: @escaping (any ParentModel) -> Void) {
        self.currentDate = currentDate
        self.currentParentId = currentParentId
        self.onSelectParent = onSelectParent
        _filterDate = State(initialValue: currentDate)
    }
    
    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Filter Date", selection: $filterDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
            
            ParentSelectionFilteredList(
                targetDate: filterDate,
                currentParentId: currentParentId,
                onSelect: { selected in
                    onSelectParent(selected)
                    dismiss()
                }
            )
        }
        .navigationTitle("Select Parent")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ParentSelectionFilteredList: View {
    @Query private var activities: [ActivityInstance]
    @Query private var trips: [Trip]
    
    let currentParentId: PersistentIdentifier?
    let onSelect: (any ParentModel) -> Void
    
    init(targetDate: Date, currentParentId: PersistentIdentifier?, onSelect: @escaping (any ParentModel) -> Void) {
        self.currentParentId = currentParentId
        self.onSelect = onSelect
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let activityPredicate = #Predicate<ActivityInstance> { $0.timeStart >= startOfDay && $0.timeStart < endOfDay }
        _activities = Query(filter: activityPredicate, sort: \.timeStart, order: .reverse)
        
        let tripPredicate = #Predicate<Trip> { $0.timeStart >= startOfDay && $0.timeStart < endOfDay }
        _trips = Query(filter: tripPredicate, sort: \.timeStart, order: .reverse)
    }
    
    var body: some View {
        Section("Activities") {
            if activities.isEmpty {
                Text("No activities found for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(activities) { instance in
                    Button {
                        onSelect(instance)
                    } label: {
                        HStack(spacing: 8) {
                            IconView(iconString: instance.activity?.icon ?? "flowchart.fill", size: 22, tint: .blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(instance.activity?.name ?? "Activity")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(instance.timeStart, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if instance.persistentModelID == currentParentId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        
        Section("Trips") {
            if trips.isEmpty {
                Text("No trips found for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(trips) { trip in
                    Button {
                        onSelect(trip)
                    } label: {
                        HStack(spacing: 8) {
                            IconView(iconString: trip.vehicle?.icon ?? "car.fill", size: 22, tint: .indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.name ?? trip.vehicle?.name ?? "Trip")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(trip.timeStart, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if trip.persistentModelID == currentParentId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
    }
}
