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

    init(trip: Trip, onEnd: (() -> Void)? = nil) {
        self.trip = trip
        self.onEnd = onEnd
    }
    
    
    var body: some View {
        VStack {
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
                    PlaceDisplayView(placeRid: trip.placeStartRid)
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                        PlaceDisplayView(placeRid: trip.placeEndRid)
                    }
                    if let metrics = trip.pathMetrics {
                        PathMetricsRowView(
                            metrics: metrics,
                            showTitle: false,
                            bubble: false
                        )
                    }
                }
                
                if !trip.persons.isEmpty {
                    Label(trip.persons.formattedNames(), systemImage: trip.persons.count > 1 ? "person.2.fill" : "person.fill")
                        .font(.headline)
                }
                
                if let details = trip.details, !details.isEmpty {
                    Text(details)
                }
                
                if trip.fitFilePath != nil {
                    Label("Vaulted", systemImage: "archivebox.fill")
                        .padding(8)
                        .background(Color.green.opacity(0.2), in: Capsule())
                        .foregroundColor(.green)
                }
                
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
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


