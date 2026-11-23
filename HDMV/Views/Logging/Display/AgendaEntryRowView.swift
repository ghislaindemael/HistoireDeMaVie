//
//  AgendaRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import SwiftUI
import SwiftData

struct AgendaEntryRowView: View {
    @Query(filter: #Predicate<DataLogOption> { $0.archived == false })
    private var allOptions: [DataLogOption]
    
    private var globalAgendaOptions: [DataLogOption] {
        allOptions.filter { $0.config?.isForAgenda == true }
    }
    
    let entry: AgendaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if !entry.daySummary.isEmpty {
                    Text(entry.daySummary)
                        .font(.body)
                } else if entry.decodedLogDetails?.options?.isEmpty ?? true {
                    Text("Summary unset.")
                        .bold()
                        .foregroundStyle(.red)
                }
                Spacer(minLength: 8)
                SyncStatusIndicator(status: entry.syncStatus)
            }
            
            LifeContextsDisplayView(contextRids: entry.contextRids)
            
            optionsPillsView
            
            LinkedFilesPillView(agendaEntry: entry)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primaryBackground))
    }
    
    // MARK: - Options Pills View
    @ViewBuilder
    private var optionsPillsView: some View {
        let engine = DynamicOptionsLayoutEngine(
            mappings: [],
            globalOptions: globalAgendaOptions,
            decodedOptions: entry.decodedLogDetails?.options,
            modelContext: entry.modelContext
        )
        let layoutView = engine.renderAll()
        
        VStack(alignment: .leading, spacing: 4) {
            layoutView
        }
    }
}
