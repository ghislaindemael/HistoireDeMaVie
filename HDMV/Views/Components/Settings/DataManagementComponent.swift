//  DataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//  Updated on 19.07.2025.
//

import SwiftUI
import SwiftData

struct DataManagementComponent: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded: Bool = false
    
    // An array of the model types to be managed by this component.
    private let modelTypes: [any PersistentModel.Type] = [
        Activity.self,
        ActivityInstance.self,
        AgendaEntry.self,
        Trip.self,
        City.self,
        Place.self,
        Person.self,
        PersonInteraction.self
    ]
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 4) {
                ForEach(modelTypes.indices, id: \.self) { index in
                    let modelType = modelTypes[index]
                    ModelRow(modelType: modelType)
                    
                    if index < modelTypes.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Cache")
                .foregroundColor(.red)
                .font(.headline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 1)
        )
    }
    
    /// A private view for each row to keep the body clean.
    private func ModelRow(modelType: any PersistentModel.Type) -> some View {
        NavigationLink {
            DataWipeDetailView(modelType: modelType)
        } label: {
            HStack {
                Text(String(describing: modelType))
                Spacer()
                Text("\(fetchCount(for: modelType))")
                    .fontWeight(.bold)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteAll(for: modelType)
            } label: {
                Label("Delete All", systemImage: "trash.fill")
            }
        }
    }
    
    // MARK: - Data Operations
    
    /// Deletes all objects of a given model type from the context.
    private func deleteAll(for modelType: any PersistentModel.Type) {
        print("Deleting all objects of type \(modelType)...")
        do {
            // The switch ensures type-safety for the delete operation.
            switch modelType {
                case is Activity.Type: try modelContext.delete(model: Activity.self)
                case is ActivityInstance.Type: try modelContext.delete(model: ActivityInstance.self)
                case is AgendaEntry.Type: try modelContext.delete(model: AgendaEntry.self)
                case is Trip.Type: try modelContext.delete(model: Trip.self)
                case is City.Type: try modelContext.delete(model: City.self)
                case is Place.Type: try modelContext.delete(model: Place.self)
                case is Person.Type: try modelContext.delete(model: Person.self)
                case is PersonInteraction.Type: try modelContext.delete(model: PersonInteraction.self)
                default: print("Warning: Unhandled model type for deletion: \(modelType)")
            }
        } catch {
            print("Failed to delete objects for \(modelType): \(error)")
        }
    }
    
    /// Fetches the current count for a given model type from the context.
    /// This function remains largely the same as it is the most type-safe approach.
    private func fetchCount(for modelType: any PersistentModel.Type) -> Int {
        do {
            switch modelType {
                case is Activity.Type: return try modelContext.fetchCount(FetchDescriptor<Activity>())
                case is ActivityInstance.Type: return try modelContext.fetchCount(FetchDescriptor<ActivityInstance>())
                case is AgendaEntry.Type: return try modelContext.fetchCount(FetchDescriptor<AgendaEntry>())
                case is Trip.Type: return try modelContext.fetchCount(FetchDescriptor<Trip>())
                case is City.Type: return try modelContext.fetchCount(FetchDescriptor<City>())
                case is Place.Type: return try modelContext.fetchCount(FetchDescriptor<Place>())
                case is Person.Type: return try modelContext.fetchCount(FetchDescriptor<Person>())
                case is PersonInteraction.Type: return try modelContext.fetchCount(FetchDescriptor<PersonInteraction>())
                default:
                    print("Warning: Unhandled model type in fetchCount: \(modelType)")
                    return 0
            }
        } catch {
            print("Failed to fetch count for \(modelType): \(error)")
            return 0
        }
    }
}


#Preview {
    NavigationStack {
        VStack {
            DataManagementComponent(expanded: true)
            Spacer()
        }
        .padding()
    }
    .modelContainer(for: [AgendaEntry.self, Trip.self, City.self, Place.self, Person.self, PersonInteraction.self])
}
