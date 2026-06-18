//
//  VehicleSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//


import SwiftUI
import SwiftData

struct CitySelectorView: View {
    @Binding var selectedCity: City?
    var title: String = "City"
    
    @Query(FetchDescriptor<City>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.slug)]))
    private var cachedCities: [City]
    
    var body: some View {
        Picker(title, selection: $selectedCity) {
            Text("None").tag(nil as City?)
            ForEach(cachedCities) { city in
                Text(city.name).tag(city as City?)
            }
        }
    }
}
