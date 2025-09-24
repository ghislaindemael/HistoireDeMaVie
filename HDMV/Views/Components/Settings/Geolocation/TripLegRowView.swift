//
//  TripRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import SwiftUI
import SwiftData

struct TripLegRowView: View {
    let tripLeg: TripLeg
    let onEnd: (() -> Void)?
    private let isSmall: Bool

    init(tripLeg: TripLeg, isSmall: Bool = true, onEnd: (() -> Void)? = nil) {
        self.tripLeg = tripLeg
        self.onEnd = onEnd
        self.isSmall = isSmall

    }
        
    var body: some View {
        VStack {
            if isSmall {
                VStack(alignment: .leading) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(vehicleId: tripLeg.vehicle_id, isSmall: isSmall)
                        
                        HStack {
                            PlaceDisplayView(placeId: tripLeg.place_start_id, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeId: tripLeg.place_end_id, isSmall: isSmall)
                            
                        }
                        Spacer()
                        SyncStatusIndicator(status: tripLeg.syncStatus)
                    }
                    DateRangeDisplayView(
                        startDate: tripLeg.time_start,
                        endDate: tripLeg.time_end
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        VehicleDisplayView(vehicleId: tripLeg.vehicle_id)
                        HStack {
                            PlaceDisplayView(placeId: tripLeg.place_start_id, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeId: tripLeg.place_end_id, isSmall: isSmall)
                        }
                        Spacer()
                        SyncStatusIndicator(status: tripLeg.syncStatus)
                    }
                    HStack(spacing: 4) {
                        PlaceDisplayView(placeId: tripLeg.place_start_id)
                        Image(systemName: "arrow.turn.down.right").padding(.leading, 2)
                        PlaceDisplayView(placeId: tripLeg.place_end_id)
                        
                    }
                    .padding(.leading, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if tripLeg.time_end == nil, let onEnd = onEnd {
                EndItemButton(title: "End Trip Leg") {
                    onEnd()
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondaryBackgroundColor)
        )
    }
    
}


