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
    let onEnd: () -> Void
    
    var body: some View {
        content
            .if(!interaction.isStandalone) { view in
                view
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondaryBackgroundColor)
                    )
            }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                PersonDisplayView(interaction: interaction)
                Spacer()
                SyncStatusIndicator(status: interaction.syncStatus)
            }
            
            DateRangeDisplayView(startDate: interaction.time_start, endDate: interaction.time_end)
            
            HStack {
                if interaction.timed == false {
                    Image(systemName: "clock")
                        .foregroundStyle(.red)
                        .bold()
                }
                if interaction.in_person {
                    Image(systemName: "person.2")
                } else {
                    Image(systemName: "phone")
                }
                GradientPercentageBarView(
                    percentage: Double(interaction.percentage ?? 100)
                )
                .frame(height: 8)
                .padding(.leading, 4)
            }
            if let details = interaction.details, !details.isEmpty {
                Text(details)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .foregroundColor(Color.primary)
                    .font(.body)
            }
            if interaction.time_end == nil {
                EndItemButton(title: "End Interaction", action: onEnd)
            }
        }
    }
}
