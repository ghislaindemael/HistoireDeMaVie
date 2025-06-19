//
//  VehicleDataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//


//
//  VehicleDataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 18.06.2025.
//

import SwiftUI
import SwiftData

struct ConfigPageLinksComponent: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded: Bool = false
    
    // Add your vehicle-related models here
    private let manageableModels: [any PersistentModel.Type] = [
        Vehicle.self,
    ]
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }

    var body: some View {
        DisclosureGroup("Config pages", isExpanded: $isExpanded) {
            VStack(spacing: 4) {
                ForEach(manageableModels.indices, id: \.self) { index in
                    let modelType = manageableModels[index]
                        
                    NavigationLink {
                        VehiclesPage()
                    } label: {
                        HStack {
                            Text(String(describing: modelType))
                            Spacer()
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
                .stroke(Color.blue, lineWidth: 1)
        )
    }
    
}


#Preview {
    NavigationStack {
        VStack {
            ConfigPageLinksComponent(expanded: true)
            Spacer()
        }
        .padding()
    }
    .modelContainer(for: [Vehicle.self, VehicleType.self])
}
