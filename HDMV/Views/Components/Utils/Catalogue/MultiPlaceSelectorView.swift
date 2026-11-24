//
//  MultiPlaceSelectorView.swift
//  HDMV
//
//  Multi-select list of cached Places bound to `[Int]` RIDs.
//

import SwiftUI
import SwiftData

struct MultiPlaceSelectorView: View {
    @Query(FetchDescriptor<Place>(
        predicate: #Predicate { $0.cache == true && $0.archived == false },
        sortBy: [SortDescriptor(\.name)]))
    private var allPlaces: [Place]
    
    @Binding var selectedRids: [Int]
    var title: String = "Select Places"
    
    @State private var searchText: String = ""
    
    private var filteredPlaces: [Place] {
        if searchText.isEmpty {
            return allPlaces
        }
        return allPlaces.filter { place in
            place.name.localizedCaseInsensitiveContains(searchText) ||
            (place.city?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        List {
            if filteredPlaces.isEmpty {
                ContentUnavailableView(
                    "No Places",
                    systemImage: "mappin.slash",
                    description: Text("Add cached places in the Settings tab first.")
                )
            } else {
                ForEach(filteredPlaces) { place in
                    if let rid = place.rid {
                        Button {
                            toggleSelection(for: rid)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name)
                                        .foregroundStyle(.primary)
                                    if let cityName = place.city?.name {
                                        Text(cityName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                
                                if selectedRids.contains(rid) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search places...")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleSelection(for rid: Int) {
        if let index = selectedRids.firstIndex(of: rid) {
            selectedRids.remove(at: index)
        } else {
            selectedRids.append(rid)
        }
    }
}
