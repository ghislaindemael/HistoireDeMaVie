//
//  InteractionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI
import SwiftData

struct InteractionRowView: View {
    @Query(filter: #Predicate<DataLogOptionMapping> { $0.isForInteraction && $0.archived == false })
    private var optionMappings: [DataLogOptionMapping]
    
    let interaction: Interaction
    let onEnd: (() -> Void)?
    
    init(interaction: Interaction, onEnd: (() -> Void)? = nil) {
        self.interaction = interaction
        self.onEnd = onEnd
    }
    
    var body: some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryBackground)
            )
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Label(interaction.persons.formattedNames(), systemImage: interaction.persons.count > 1 ? "person.2.fill" : "person.fill")
                    .font(.headline)
                    .foregroundStyle(interaction.persons.isEmpty ? .red : .primary)
                Spacer()
                SyncStatusIndicator(status: interaction.syncStatus)
            }
            
            HStack {
                DateRangeDisplayView(
                    startDate: interaction.timeStart,
                    endDate: interaction.timeEnd,
                    selectedDate: interaction.timeStart
                )
            }
            
            if !interaction.timed {
                HStack() {
                    Image(systemName: "clock.badge.xmark")
                        .foregroundStyle(.red)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.red)
                        .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
            } else if interaction.percentage != 100 {
                GradientPercentageBarView(percentage: Double(interaction.percentage))
                    .frame(height: 10)
            }
            
            if let details = interaction.details, !details.isEmpty {
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
            
            LifeContextsDisplayView(contextRids: interaction.contextRids)
            
            optionsPillsView
            
            if interaction.timeEnd == nil, let onEnd = onEnd {
                EndItemButton(title: "End Interaction", action: onEnd)
            }
        }
    }
    
    // MARK: - Options Pills View
    @ViewBuilder
    private var optionsPillsView: some View {
        let engine = DynamicOptionsLayoutEngine(mappings: optionMappings, decodedOptions: interaction.decodedLogDetails?.options)
        let layoutView = engine.renderAll()
        
        VStack(alignment: .leading, spacing: 4) {
            layoutView
            missingRequiredOptionsWarnings
        }
    }
    
    @ViewBuilder
    private var missingRequiredOptionsWarnings: some View {
        let missing = optionMappings.filter { mapping in
            !mapping.isDeleted && mapping.required && (interaction.decodedLogDetails?.options?[mapping.optionSlug] == nil || interaction.decodedLogDetails?.options?[mapping.optionSlug]?.isEmpty == true)
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
