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
                        VehicleDisplayView(vehicleRid: tripLeg.vehicle?.rid, isSmall: isSmall)
                        
                        HStack {
                            PlaceDisplayView(placeId: tripLeg.placeStart?.rid, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeId: tripLeg.placeEnd?.rid, isSmall: isSmall)
                            
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
                        VehicleDisplayView(vehicleRid: tripLeg.vehicle?.rid)
                        HStack {
                            PlaceDisplayView(placeId: tripLeg.placeStart?.rid, isSmall: isSmall)
                            Image(systemName: "arrow.right").padding(.leading, 2)
                            PlaceDisplayView(placeId: tripLeg.placeEnd?.rid, isSmall: isSmall)
                        }
                        Spacer()
                        SyncStatusIndicator(status: tripLeg.syncStatus)
                    }
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


