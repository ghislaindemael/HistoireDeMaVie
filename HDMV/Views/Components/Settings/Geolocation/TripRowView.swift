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
                PlaceDisplayView(placeRid: trip.placeStartRid)
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                    PlaceDisplayView(placeRid: trip.placeEndRid)
                }
                
                let metrics = trip.pathMetrics ?? trip.path?.metrics
                if trip.transitLine != nil || trip.path != nil || metrics != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        if let transitLine = trip.transitLine {
                            HStack(spacing: 4) {
                                Image(systemName: "tram.fill")
                                Text(transitLine.name)
                            }
                            .fontWeight(.semibold)

                        } else if let path = trip.path {
                            HStack(spacing: 4) {
                                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                Text(path.name)
                            }
                            .fontWeight(.semibold)

                        }
                        
                        if let metrics = metrics {
                            PathMetricsRowView(
                                metrics: metrics,
                                showTitle: false,
                                bubble: false
                            )
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
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
                
                LifeContextsDisplayView(contextRids: trip.contextRids)
                
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


