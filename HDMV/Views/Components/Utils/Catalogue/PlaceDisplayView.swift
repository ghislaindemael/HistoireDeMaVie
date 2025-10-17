//
//  PlaceDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.09.2025.
//


import SwiftUI
import SwiftData

struct PlaceDisplayView: View {
    @Query private var places: [Place]
    
    private let placeId: Int?
    private let isSmall: Bool
    
    private var place: Place? {
        places.first
    }

    init(placeId: Int?, isSmall: Bool = false) {
        self.placeId = placeId
        self.isSmall = isSmall
        
        if let id = placeId, id > 0 {
            _places = Query(filter: #Predicate { $0.rid == id })
        } else {
            _places = Query(filter: #Predicate { _ in false })
        }
    }
    
    var body: some View {
        if let place = place {
            if isSmall {
                Text(place.city?.name ?? "—")
                    .foregroundStyle(.secondary)
            } else {
                let cityName = place.city?.name ?? "—"
                let placeName = place.name ?? "Unnamed"
                Text("\(cityName) – \(placeName)")
            }
        } else if let id = placeId, id > 0 {
            Text("Uncached")
                .foregroundStyle(.orange)
        } else {
            Text("Unset")
                .foregroundStyle(.red)
                .fontWeight(.semibold)
        }
    }
}
