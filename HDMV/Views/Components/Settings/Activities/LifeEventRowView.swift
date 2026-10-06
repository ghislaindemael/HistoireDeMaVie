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
    
    @Query(filter: #Predicate<DataLogOptionMapping> { $0.isForLifeEvent && $0.archived == false })
    private var optionMappings: [DataLogOptionMapping]
    
    let event: LifeEvent
    let selectedDate: Date
    
    init(
        event: LifeEvent,
        selectedDate: Date,
    ) {
        self.event = event
        self.selectedDate = selectedDate
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
                        iconString: event.type.icon,
                        size: 30,
                        tint: event.type == .unset ? .red : .primary,
                    )
                    
                    VStack(alignment: .leading) {
                        Text(event.type.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(event.type != .unset ? Color.primary : Color.red)
                        DateRangeDisplayView(
                            startDate: event.timeStart,
                            endDate: event.timeEnd,
                            selectedDate: selectedDate
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
            
            
            // TODO: Show metrics sliders
            
            LifeContextsDisplayView(contextRids: event.contextRids)
            
            optionsPillsView
        }
    }
    
    // MARK: - Options Pills View
    @ViewBuilder
    private var optionsPillsView: some View {
        let engine = DynamicOptionsLayoutEngine(mappings: optionMappings, decodedOptions: event.decodedLogDetails?.options)
        let layoutView = engine.renderAll()
        
        VStack(alignment: .leading, spacing: 4) {
            layoutView
            missingRequiredOptionsWarnings
        }
    }
    
    @ViewBuilder
    private var missingRequiredOptionsWarnings: some View {
        let missing = optionMappings.filter { mapping in
            !mapping.isDeleted && mapping.required && (event.decodedLogDetails?.options?[mapping.optionSlug] == nil || event.decodedLogDetails?.options?[mapping.optionSlug]?.isEmpty == true)
        }
        
        if !missing.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(missing, id: \.id) { mapping in
                    MissingDetailWarningView(
                        message: "Missing \(mapping.option?.name ?? mapping.optionSlug)",
                        iconName: "exclamationmark.triangle.fill",
                        isRequired: true
                    )
                }
            }
        }
    }
}
