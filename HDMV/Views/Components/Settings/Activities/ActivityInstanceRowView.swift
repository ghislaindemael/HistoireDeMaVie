//
//  ActivityInstanceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct ActivityInstanceRowView: View {
    @Environment(\.modelContext) private var modelContext
    
    let instance: ActivityInstance
    let activity: Activity?
    let tripLegs: [TripLeg]
    let tripLegsVehicles: [Vehicle]
    let tripLegsPlaces: [Place]
    let onStartTripLeg: (Int) -> Void
    let onEditTripLeg: (TripLeg) -> Void
    let onEndTripLeg: (TripLeg) -> Void
    
    var hasActiveLeg: Bool {
        tripLegs.contains { $0.time_end == nil }
    }

        
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                IconView(iconString: activity?.icon ?? "questionmark.circle")
                    .font(.title2)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(activity?.name ?? "Unassigned Activity")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(instance.time_start, style: .time)
                        Text("-")
                        if let timeEnd = instance.time_end {
                            Text(timeEnd, style: .time)
                        } else {
                            Text("In Progress").foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                SyncStatusIndicator(status: instance.syncStatus)
            }
            .padding(.vertical, 4)
            
            if activity?.canCreateTripLegs == true {
                tripLegsSection
                    .padding(.leading, 30)
                
                if instance.time_end == nil && !hasActiveLeg {
                    StartItemButton(title: "Start trip leg") {
                        onStartTripLeg(instance.id)
                    }
                }
            }
            
        }
    }
    
    @ViewBuilder
    private var tripLegsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(tripLegs) { leg in
                Button(action: { onEditTripLeg(leg) }) {
                    VStack{
                        TripLegRowView(
                            tripLeg: leg,
                            vehicle: tripLegsVehicles.first(where: {$0.id == leg.vehicle_id}),
                            places: tripLegsPlaces
                        )
                        if leg.time_end == nil {
                            EndItemButton(title: "End Trip Leg") {
                                onEndTripLeg(leg)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            
            
        }
    }
}

