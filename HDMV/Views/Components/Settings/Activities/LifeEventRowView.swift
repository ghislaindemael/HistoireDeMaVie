//
//  LifeEventRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct LifeEventRowView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = SettingsStore.shared
    
    private var optionMappings: [DataLogOptionMapping] {
        event.type?.optionMappings.filter { !$0.archived }.sorted { $0.priority < $1.priority } ?? []
    }
    
    let event: LifeEvent
    let selectedDate: Date
    var showParentBadge: Bool = false
    
    init(
        event: LifeEvent,
        selectedDate: Date,
        showParentBadge: Bool = false
    ) {
        self.event = event
        self.selectedDate = selectedDate
        self.showParentBadge = showParentBadge
    }
    
    
    var body: some View {
        VStack {
            basicsSection
            detailsSection
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryBackground)
        )
        
    }
    
    @ViewBuilder
    private var basicsSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                HStack() {
                    IconView(
                        iconString: event.type?.icon ?? "questionmark.circle",
                        size: 30,
                        tint: event.type == nil ? .red : .primary,
                    )
                    
                    VStack(alignment: .leading) {
                        Text(event.type?.name ?? "Unknown Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(event.type != nil ? Color.primary : Color.red)
                        DateRangeDisplayView(
                            startDate: event.timeStart,
                            endDate: event.timeEnd,
                            selectedDate: selectedDate,
                            startTimeZone: event.resolvedStartTimeZone(in: modelContext),
                            endTimeZone: event.resolvedEndTimeZone(in: modelContext)
                        )
                        .font(.subheadline)
                        
                    }
                    Spacer()
                    
                }
                
            }
            .padding(.vertical, 4)
            
            SyncStatusIndicator(status: event.syncStatus)
                .padding([.top, .trailing], 0)
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack {
            
            if let details = event.details, !details.isEmpty {
                Text(details)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondaryBackground)
                    )
                    .foregroundColor(Color.primary)
                    .font(.body)
            }
            
            if showParentBadge {
                if let parent = event.parentInstance {
                    HStack(spacing: 8) {
                        Label(parent.activity?.name ?? "Activity", systemImage: parent.activity?.icon ?? "flowchart.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let parentTrip = event.parentTrip {
                    HStack(spacing: 8) {
                        Label(parentTrip.vehicle?.name ?? "Trip", systemImage: parentTrip.vehicle?.icon ?? "car.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            
            // TODO: Show metrics sliders
            
            LifeContextsDisplayView(contextRids: event.contextRids)
            
            LinkedFilesPillView(lifeEvent: event)
            
            optionsPillsView
        }
    }
    
    // MARK: - Options Pills View
    @ViewBuilder
    private var optionsPillsView: some View {
        let engine = DynamicOptionsLayoutEngine(
            mappings: optionMappings,
            decodedOptions: event.decodedLogDetails?.options,
            modelContext: modelContext
        )
        let layoutView = engine.renderAll()
        
        VStack(alignment: .leading, spacing: 4) {
            layoutView
        }
    }
}
