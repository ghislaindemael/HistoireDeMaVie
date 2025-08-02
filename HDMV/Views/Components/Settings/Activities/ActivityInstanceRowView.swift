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
            
            if activity?.generate_trips == true {
                tripLegsSection
                    .padding(.leading, 30)
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
            
            Button(action: {
                onStartTripLeg(instance.id)
            }) {
                Label("New Trip Leg", systemImage: "plus.circle")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .buttonStyle(.plain)
        }
    }
}

