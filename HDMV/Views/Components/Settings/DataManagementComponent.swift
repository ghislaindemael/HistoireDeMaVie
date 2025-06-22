//
//  DataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//

import SwiftUI
import SwiftData

struct DataManagementComponent: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded: Bool = false
    
    private let manageableModels: [any PersistentModel.Type] = [
        Meal.self,
        AgendaEntry.self,
        Trip.self,
    ]
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }

    var body: some View {
        DisclosureGroup("Data Management", isExpanded: $isExpanded) {
            VStack(spacing: 4) {
                // Loop through each manageable model type
                ForEach(manageableModels.indices, id: \.self) { index in
                    let modelType = manageableModels[index]
                    
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
                    
                    if index < manageableModels.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 1) 
        )
    }
    
    /// Fetches the current count for a given model type from the context.
    private func fetchCount(for modelType: any PersistentModel.Type) -> Int {
        do {
            switch modelType {
                case is Meal.Type:
                    let descriptor = FetchDescriptor<Meal>()
                    return try modelContext.fetchCount(descriptor)
                case is AgendaEntry.Type:
                    let descriptor = FetchDescriptor<AgendaEntry>()
                    return try modelContext.fetchCount(descriptor)
                case is Trip.Type:
                    let descriptor = FetchDescriptor<Trip>()
                    return try modelContext.fetchCount(descriptor)
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
    // Remember to add a model container for the preview to work
    .modelContainer(for: [Meal.self, MealType.self, AgendaEntry.self])
}
