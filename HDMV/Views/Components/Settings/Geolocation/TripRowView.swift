//
//  TripRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import SwiftUI
import SwiftData

struct TripRowView: View {
    let trip: Trip
    let onEnd: (() -> Void)?
    private let isSmall: Bool

    init(trip: Trip, isSmall: Bool = true, onEnd: (() -> Void)? = nil) {
        self.trip = trip
        self.onEnd = onEnd
        self.isSmall = isSmall

    }
        
    var body: some View {
        VStack {
            if isSmall {
                VStack(alignment: .leading) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(vehicleRid: trip.vehicle?.rid, isSmall: isSmall)
                        
                        HStack {
                            PlaceDisplayView(placeRid: trip.placeStart?.rid, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeRid: trip.placeEnd?.rid, isSmall: isSmall)
                            
                        }
                        Spacer()
                        SyncStatusIndicator(status: trip.syncStatus)
                    }
                    DateRangeDisplayView(
                        startDate: trip.timeStart,
                        endDate: trip.timeEnd
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(vehicleRid: trip.vehicle?.rid)
                        HStack {
                            PlaceDisplayView(placeRid: trip.placeStart?.rid, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeRid: trip.placeEnd?.rid, isSmall: isSmall)
                        }
                        Spacer()
                        SyncStatusIndicator(status: trip.syncStatus)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if trip.timeEnd == nil, let onEnd = onEnd {
                EndItemButton(title: "End Trip") {
                    onEnd()
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryBackground)
        )
    }
    
}


