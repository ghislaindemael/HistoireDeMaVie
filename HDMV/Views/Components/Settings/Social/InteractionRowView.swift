//
//  InteractionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI
import SwiftData

struct InteractionRowView: View {
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
                PersonDisplayView(interaction: interaction)
                Spacer()
                SyncStatusIndicator(status: interaction.syncStatus)
            }
            
            HStack {
                if interaction.inPerson {
                    Image(systemName: "person.2")
                } else {
                    Image(systemName: "phone")
                }
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
            if interaction.timeEnd == nil, let onEnd = onEnd {
                EndItemButton(title: "End Interaction", action: onEnd)
            }
        }
    }
}
