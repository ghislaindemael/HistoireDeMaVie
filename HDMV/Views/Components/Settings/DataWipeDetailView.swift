//
//  DataWipeDetailView.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//

import SwiftUI
import SwiftData

struct DataWipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var items: [any PersistentModel] = []
    
    
    /// The specific model type this view will manage (e.g., Meal.self).
    let modelType: any PersistentModel.Type
    
    @State private var count: Int = 0
    @State private var isShowingConfirmAlert = false
    
    private var modelName: String {
        String(describing: modelType)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("This tool will permanently delete all data for the selected model type.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            List {
                ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                    describeView(for: item)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            
            HStack {
                Text("Objects to delete:")
                Spacer()
                Text("\(count)")
                    .font(.title.bold())
            }
            
            Spacer()
            
            Button(role: .destructive) {
                isShowingConfirmAlert = true
            } label: {
                Label("Delete All \(modelName) Objects", systemImage: "trash.fill")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(count == 0)
        }
        .padding()
        .navigationTitle(modelName)
        .onAppear(perform: fetchItems)
        .alert("Are you sure?", isPresented: $isShowingConfirmAlert) {
            Button("Delete All", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You are about to permanently delete \(count) \(modelName) objects. This action cannot be undone.")
        }
    }
    
    /// Fetches the count of objects for the current model type.
    private func fetchItems() {
        do {
            switch modelType {
                case is Activity.Type:
                    let descriptor = FetchDescriptor<Activity>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is ActivityInstance.Type:
                    let descriptor = FetchDescriptor<ActivityInstance>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is AgendaEntry.Type:
                    let descriptor = FetchDescriptor<AgendaEntry>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Trip.Type:
                    let descriptor = FetchDescriptor<Trip>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is City.Type:
                    let descriptor = FetchDescriptor<City>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Place.Type:
                    let descriptor = FetchDescriptor<Place>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Person.Type:
                    let descriptor = FetchDescriptor<Person>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is PersonInteraction.Type:
                    let descriptor = FetchDescriptor<PersonInteraction>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                default:
                    print("Warning: Unhandled model type in fetchItems: \(modelType)")
                    items = []
                    count = 0
            }
        } catch {
            print("Failed to fetch items: \(error)")
            items = []
            count = 0
        }
    }
    
    
    /// Performs the deletion of all objects for the current model type.
    private func deleteAllData() {
        do {
            try modelContext.delete(model: modelType)
            print("Successfully deleted all \(modelName) objects.")
            fetchItems()
        } catch {
            print("Failed to delete \(modelName) objects: \(error)")
        }
    }
    
    private func describeView(for item: any PersistentModel) -> AnyView {
        switch item {
            case let activity as Activity:
                return AnyView(
                    ActivityRowView(activity: activity)
                )
            case let entry as AgendaEntry:
                return AnyView(
                    VStack(alignment: .leading) {
                        Text(entry.date)
                        Text(entry.daySummary)
                            .font(.headline)
                    }
                )
            case let city as City:
                return AnyView(
                    Text(city.name)
                )
            case let place as Place:
                return AnyView(
                    Text(place.localName)
                )
            case let person as Person:
                return AnyView(
                    Text(person.fullName)
                )
            case let interaction as PersonInteraction:
                return AnyView(
                    PersonInteractionRowView(interaction: interaction, person: nil)
                )
            default:
                return AnyView(Text("Unknown Object"))
        }
    }
    
    
    private func deleteItem(_ item: any PersistentModel) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            fetchItems()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
}


#Preview {
    NavigationStack {
        DataWipeDetailView(modelType: AgendaEntry.self)
    }
    .modelContainer(for: AgendaEntry.self)
}
