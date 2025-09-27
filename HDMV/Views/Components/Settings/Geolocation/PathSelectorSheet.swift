//
//  PathSelectorSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.09.2025.
//


import SwiftUI
import SwiftData

struct PathSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Path.name) private var paths: [Path]
    @Query(sort: \City.name) private var cities: [City]
    @Query private var places: [Place]
    
    @State private var selectedCity: City? = nil
    
    let onPathSelected: (Int) -> Void
    
    private var filteredPaths: [Path] {
        guard let selectedCity = selectedCity else { return paths }
        let placeIDsInCity = places.filter { $0.city_id == selectedCity.id }.map { $0.id }
        let placeIDSet = Set(placeIDsInCity)
        return paths.filter { path in
            guard let startID = path.place_start_id, let endID = path.place_end_id else { return false }
            return placeIDSet.contains(startID) || placeIDSet.contains(endID)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Filter") {
                    Picker("City", selection: $selectedCity) {
                        Text("All Cities").tag(nil as City?)
                        ForEach(cities) { city in
                            Text(city.name).tag(city as City?)
                        }
                    }
                }
                
                Section("Paths") {
                    ForEach(filteredPaths) { path in
                        Button(action: {
                            onPathSelected(path.id)
                            dismiss()
                        }) {
                            PathRowView(path: path)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Select a Path")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
