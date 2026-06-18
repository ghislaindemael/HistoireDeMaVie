//
//  ParentCitySelectorView.swift
//  HDMV
//

import SwiftUI
import SwiftData

struct ParentCitySelectorView: View {
    @Binding var selectedCity: City?
    var title: String = "Parent City"
    
    @Query(FetchDescriptor<Country>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.slug)]))
    private var countries: [Country]
    
    @Query(
        filter: #Predicate<City> { $0.country == nil && $0.parentCity == nil },
        sort: \.slug
    ) private var orphanedCities: [City]
    
    @State private var filterCountry: Country?
    
    var body: some View {
        NavigationLink(destination: selectorList) {
            HStack {
                Text(title)
                Spacer()
                Text(selectedCity?.name ?? "None")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var selectorList: some View {
        Form {
            Section("Country Filter") {
                Picker("Country", selection: $filterCountry) {
                    Text("No country").tag(nil as Country?)
                    ForEach(countries) { country in
                        Text(country.name).tag(country as Country?)
                    }
                }
            }
            
            Section("Cities") {
                Button(action: {
                    selectedCity = nil
                }) {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedCity == nil {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                if let filterCountry = filterCountry {
                    ForEach(filterCountry.rootCities) { city in
                        CitySelectorNodeView(city: city, selectedCity: $selectedCity)
                    }
                } else {
                    ForEach(orphanedCities) { city in
                        CitySelectorNodeView(city: city, selectedCity: $selectedCity)
                    }
                }
            }
        }
        .navigationTitle("Select \(title)")
    }
}

struct CitySelectorNodeView: View {
    let city: City
    @Binding var selectedCity: City?
    
    var body: some View {
        if city.sortedChildren.isEmpty {
            rowContent
        } else {
            DisclosureGroup {
                ForEach(city.sortedChildren) { child in
                    CitySelectorNodeView(city: child, selectedCity: $selectedCity)
                }
            } label: {
                rowContent
            }
        }
    }
    
    private var rowContent: some View {
        Button(action: {
            selectedCity = city
        }) {
            HStack {
                UnsettableTextView(
                    text: city.name,
                    font: .body,
                    isItalicized: city.archived
                )
                Spacer()
                if selectedCity == city {
                    Image(systemName: "checkmark").foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
}
