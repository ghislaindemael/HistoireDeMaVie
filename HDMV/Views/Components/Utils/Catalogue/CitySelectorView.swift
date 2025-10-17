//
//  VehicleSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//


import SwiftUI
import SwiftData

struct CitySelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedCity: City?
    
    @Query(FetchDescriptor<City>(
        predicate: #Predicate { $0.cache == true && $0.name != nil },
            sortBy: [SortDescriptor(\.name)]))
    private var cities: [City]
    
    var body: some View {
        VStack {
            Picker("City", selection: $selectedCity) {
                Text("None").tag(nil as City?)
                ForEach(cities) { city in
                    Text(city.name!).tag(city as City?)
                }
            }
        }
    }
}
