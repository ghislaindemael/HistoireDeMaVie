//
//  AgendaRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import SwiftUI

struct AgendaEntryRowView: View {
    let entry: AgendaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if !entry.daySummary.isEmpty {
                    Text(entry.daySummary)
                        .font(.body)
                } else if entry.moodComments.isEmpty {
                    Text("Summary unset.")
                        .bold()
                        .foregroundStyle(.red)
                }
                Spacer(minLength: 8)
                SyncStatusIndicator(status: entry.syncStatus)
            }
            GradientPercentageBarView(percentage: Double(entry.mood * 10))
                .frame(height: 8)

            if !entry.moodComments.isEmpty {
                Text(entry.moodComments)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primaryBackground))
    }
}
