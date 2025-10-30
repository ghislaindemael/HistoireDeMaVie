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
    private let smallDisplay: Bool

    init(trip: Trip, smallDisplay: Bool = true, onEnd: (() -> Void)? = nil) {
        self.trip = trip
        self.onEnd = onEnd
        self.smallDisplay = smallDisplay

    }
        
    var body: some View {
        VStack {
            if smallDisplay {
                VStack(alignment: .leading) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(vehicleRid: trip.vehicle?.rid, isSmall: smallDisplay)
                        
                        HStack {
                            PlaceDisplayView(placeRid: trip.placeStart?.rid, isSmall: smallDisplay)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeRid: trip.placeEnd?.rid, isSmall: smallDisplay)
                            
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
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VehicleDisplayView(vehicleRid: trip.vehicle?.rid)
                        Spacer()
                        SyncStatusIndicator(status: trip.syncStatus)
                    }
                    PlaceDisplayView(placeRid: trip.placeStart?.rid, isSmall: smallDisplay)

                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                        PlaceDisplayView(placeRid: trip.placeEnd?.rid, isSmall: smallDisplay)
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


