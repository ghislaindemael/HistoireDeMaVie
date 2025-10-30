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
    
    private let placeRid: Int?
    private let isSmall: Bool
    private let showMapPin: Bool
    private let color: Color
    private let fontWeight: Font.Weight
    
    private var place: Place? {
        places.first
    }

    init(
        placeRid: Int?,
        isSmall: Bool = false,
        showMapPin: Bool = false,
        color: Color? = .red,
        fontWeight: Font.Weight? = .regular
    ) {
        self.placeRid = placeRid
        self.isSmall = isSmall
        self.showMapPin = showMapPin
        self.color = color ?? .red
        self.fontWeight = fontWeight ?? .regular
        
        if let rid = placeRid {
            _places = Query(filter: #Predicate { $0.rid == rid })
        } else {
            _places = Query(filter: #Predicate { _ in false })
        }
    }
    
    var body: some View {
        HStack {
            if let place = place {
                if showMapPin {
                    IconView(iconString: "mappin.circle")
                }
                if isSmall {
                    Text(place.city?.name ?? "—")
                } else {
                    let cityName = place.city?.name ?? "—"
                    Text("\(cityName) – \(place.name)")
                }
            } else if let id = placeRid, id > 0 {
                if showMapPin {
                    IconView(iconString: "mappin.circle", tint: .orange)
                }
                Text(isSmall == false ? "Place uncached" : "Uncached")
                    .foregroundStyle(.orange)
            } else {
                if showMapPin { IconView(iconString: "mappin.circle", tint: color) }
                Text(isSmall ? "Unset" : "Place unset")
                    .foregroundStyle(color)
                    .fontWeight(fontWeight)
            }
        }
    }
}
