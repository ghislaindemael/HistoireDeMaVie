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
    let person: Person?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(
                            person != nil ? .primary :
                                (interaction.person_id > 0 ? .orange : .red)
                        )
                    if let person = person {
                        Text(person.fullName)
                    } else if interaction.person_id > 0 {
                        Text("\(interaction.person_id): Uncached Person")
                            .italic()
                            .foregroundColor(.orange)
                    } else {
                        Text("Person not set")
                            .bold()
                            .foregroundColor(.red)
                    }
                }

                Spacer()
                SyncStatusIndicator(status: interaction.syncStatus)
            }
            
            HStack {
                Text(DateFormatter.timeOnly.string(from: interaction.time_start))
                Image(systemName: "arrow.right")
                if let time_end = interaction.time_end {
                    Text(DateFormatter.timeOnly.string(from: time_end))
                }
            }
            HStack {
                if interaction.in_person {
                    Image(systemName: "person.2")
                } else {
                    Image(systemName: "phone")
                }
                GradientPercentageBarView(percentage: Double(interaction.percentage))
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
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
