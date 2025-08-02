//
//  TripRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import SwiftUI
import SwiftData

struct TripLegRowView: View {

    let isSmall: Bool = true
    let tripLeg: TripLeg
    let vehicle: Vehicle?
    let places: [Place]
    
    private var startPlace: Place? {
        places.first { $0.id == tripLeg.place_start_id }
    }
    
    private var endPlace: Place? {
        places.first { $0.id == tripLeg.place_end_id }
    }
    
    var body: some View {
        if isSmall {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(String(vehicle?.label.prefix(1) ?? "(?)"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    HStack {
                        if startPlace != nil {
                            Text(startPlace!.city_name)
                        } else if tripLeg.place_start_id != nil {
                            Text("Uncached")
                                .foregroundStyle(.orange)
                            
                        } else {
                            Text("Not set")
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        }
                        
                        Image(systemName: "arrow.right")
                            .padding(.leading, 2)
                        
                        if tripLeg.time_end == nil {
                            BlinkingDotsView()
                        } else if endPlace != nil {
                            Text(endPlace!.city_name)
                        } else if tripLeg.place_end_id != nil {
                            Text("Uncached")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Not set")
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        }
                    }
                    Spacer()
                    SyncStatusIndicator(status: tripLeg.syncStatus)
                }
                HStack {
                    Text(tripLeg.time_start, style: .time)
                    Image(systemName: "arrow.right")
                    if let endTime = tripLeg.time_end {
                        Text(endTime, style: .time)
                    } else {
                        BlinkingDotsView()
                    }
                    Spacer()
                }
                
            }
        } else {
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(vehicle?.label ?? "(?) No Vehicle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    SyncStatusIndicator(status: tripLeg.syncStatus)
                }
                HStack {
                    Text(tripLeg.time_start, style: .time)
                        .font(.headline)
                    
                    Image(systemName: "arrow.right")
                    
                    if let endTime = tripLeg.time_end {
                        Text(endTime, style: .time)
                            .font(.headline)
                    } else {
                        BlinkingDotsView()
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(startPlace?.localName ?? "Unknown Start")
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .padding(.leading, 2)
                        
                        Text(endPlace?.localName ?? (tripLeg.time_end == nil ? "Not set" : "Unknown End"))
                        
                    }
                }
                .padding(.leading, 4)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
