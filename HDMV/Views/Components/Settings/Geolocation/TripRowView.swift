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

    init(trip: Trip, smallDisplay: Bool = false, onEnd: (() -> Void)? = nil) {
        self.trip = trip
        self.onEnd = onEnd
        self.smallDisplay = smallDisplay

    }
        
    var body: some View {
        VStack {
            if smallDisplay {
                VStack(alignment: .leading) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(trip: trip, isSmall: smallDisplay)
                        
                        HStack {
                            PlaceDisplayView(placeRid: trip.placeStartRid, isSmall: smallDisplay)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeRid: trip.placeEndRid, isSmall: smallDisplay)
                            
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
                        VehicleDisplayView(trip: trip)
                        
                        Spacer()
                        SyncStatusIndicator(status: trip.syncStatus)
                    }
                    DateRangeDisplayView(
                        startDate: trip.timeStart,
                        endDate: trip.timeEnd,
                        selectedDate: trip.timeStart
                    )
                    if let path = trip.path {
                        PathDisplayView(path: path)
                    } else {
                        PlaceDisplayView(placeRid: trip.placeStartRid, isSmall: smallDisplay)
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                            PlaceDisplayView(placeRid: trip.placeEndRid, isSmall: smallDisplay)
                        }
                        if let metrics = trip.pathMetrics {
                            PathMetricsRowView(
                                metrics: metrics,
                                showTitle: false,
                                bubble: false
                            )
                        }
                    }
                    
                    if let details = trip.details, !details.isEmpty {
                        Text(details)
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


