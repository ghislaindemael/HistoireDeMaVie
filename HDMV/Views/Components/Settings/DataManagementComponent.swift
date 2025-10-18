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
    
    private let modelTypes: [any PersistentModel.Type] = [
        Activity.self,
        ActivityInstance.self,
        AgendaEntry.self,
        Country.self,
        City.self,
        Path.self,
        Place.self,
        Person.self,
        PersonInteraction.self,
        Trip.self,
        Vehicle.self
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
        
    }
    
    // MARK: - Data Operations
        
    /// Fetches the current count for a given model type from the context.
    /// This function remains largely the same as it is the most type-safe approach.
    private func fetchCount<T: PersistentModel>(for modelType: T.Type) -> Int {
        do {
            return try modelContext.fetchCount(FetchDescriptor<T>())
        } catch {
            print("❌ Failed to fetch count for \(modelType): \(error)")
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
