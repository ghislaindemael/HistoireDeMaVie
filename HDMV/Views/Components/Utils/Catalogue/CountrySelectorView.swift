//
//  CountrySelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import SwiftUI
import SwiftData

struct CountrySelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedCountry: Country?
    
    @Query(FetchDescriptor<Country>(
        predicate: #Predicate { $0.cache == true && $0.name != nil },
            sortBy: [SortDescriptor(\.name)]))
    private var countries: [Country]
    
    var body: some View {
        VStack {
            Picker("Country", selection: $selectedCountry) {
                Text("None").tag(nil as Country?)
                ForEach(countries) { country in
                    Text(country.name!).tag(country as Country?)
                }
            }
        }
    }
}
