//
//  PlaceTypeSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2026.
//

import SwiftUI
import SwiftData

struct PlaceTypeSelectorView: View {
    @Binding var selectedPlaceType: PlaceType?
    
    @Query(filter: #Predicate<PlaceType> { $0.cache == true && $0.archived == false },
           sort: \PlaceType.name)
    private var placeTypes: [PlaceType]
    
    var body: some View {
        Picker("Place Type", selection: $selectedPlaceType) {
            Text("None").tag(nil as PlaceType?)
            ForEach(placeTypes) { type in
                HStack(spacing: 6) {
                    if let icon = type.icon, !icon.isEmpty {
                        IconView(iconString: icon, size: 14)
                    }
                    Text(type.name)
                }
                .tag(type as PlaceType?)
            }
        }
    }
}
