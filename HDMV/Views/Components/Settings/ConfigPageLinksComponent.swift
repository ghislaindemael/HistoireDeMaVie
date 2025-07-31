//
//  VehicleDataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import SwiftUI
import SwiftData

struct ConfigPageLink {
    let title: String
    let destination: AnyView
}


struct ConfigPageLinksComponent: View {
    
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var settings = SettingsStore.shared
    @State private var isExpanded: Bool = false
    
    private let configPages: [ConfigPageLink] = [
        ConfigPageLink(title: "Countries", destination: AnyView(CountriesPage())),
        ConfigPageLink(title: "Cities", destination: AnyView(CitiesPage())),
        ConfigPageLink(title: "Places", destination: AnyView(PlacesPage())),
        ConfigPageLink(title: "People", destination: AnyView(PeoplePage())),
        ConfigPageLink(title: "Vehicle", destination: AnyView(VehiclesPage())),
        ConfigPageLink(title: "VehicleTypes", destination: AnyView(VehicleTypesPage())),
        
    ]
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }

    var body: some View {
        DisclosureGroup("Configuration", isExpanded: $isExpanded) {
            VStack(spacing: 4) {
                Toggle("Fetch archived", isOn: $settings.includeArchived)
                ForEach(configPages.indices, id: \.self) { index in
                    let page = configPages[index]
                    
                    NavigationLink {
                        page.destination
                    } label: {
                        HStack {
                            Text(page.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    
                    if index < configPages.count - 1 {
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
