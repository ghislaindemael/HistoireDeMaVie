//
//  PersonInteractionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI
import SwiftData

struct PersonInteractionRowView: View {
    let interaction: PersonInteraction
    let instance: ActivityInstance?
    let onEnd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                PersonDisplayView(personId: interaction.person_id)
                Spacer()
                SyncStatusIndicator(status: interaction.syncStatus)
            }
            
            HStack {
                let startInfo = interaction.effectiveStart(instance: instance)
                if let start = startInfo.date {
                    Text(DateFormatter.timeOnly.string(from: start))
                        .fontWeight(startInfo.overridden ? .bold : .regular)
                } else {
                    Text("—").foregroundColor(.secondary)
                }
                
                Image(systemName: "arrow.right")
                
                let endInfo = interaction.effectiveEnd(instance: instance)
                if let end = endInfo.date {
                    Text(DateFormatter.timeOnly.string(from: end))
                        .fontWeight(endInfo.overridden ? .bold : .regular)
                } else {
                    Text("—").foregroundColor(.secondary)
                }
            }
            
            HStack {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
