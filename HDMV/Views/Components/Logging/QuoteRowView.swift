//
//  QuoteRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct QuoteRowView: View {
    @Environment(\.modelContext) private var modelContext
    let quote: Quote
    var selectedDate: Date? = nil
    var showParentBadge: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                IconView(
                    iconString: "quote.bubble",
                    size: 24,
                    tint: .primary
                )
                DateDisplayView(
                    date: quote.timeStart,
                    selectedDate: selectedDate ?? quote.timeStart,
                    timeZone: quote.resolvedStartTimeZone(in: modelContext)
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                Spacer()
                SyncStatusIndicator(status: quote.syncStatus)
            }
            
            Text(quote.text.isEmpty ? "No text" : quote.text)
                .font(.body)
                .italic()
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondaryBackground)
                )
            
            HStack {
                if let person = quote.person {
                    Text("🗣️ \(person.name)")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if let author = quote.authorString {
                    Text("- \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if showParentBadge {
                if let parentInteraction = quote.parentInteraction {
                    HStack(spacing: 8) {
                        Label(parentInteraction.persons.formattedNames(), systemImage: parentInteraction.persons.count > 1 ? "person.2.fill" : "person.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let parent = quote.parentInstance {
                    HStack(spacing: 8) {
                        Label(parent.activity?.name ?? "Activity", systemImage: parent.activity?.icon ?? "flowchart.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let parentTrip = quote.parentTrip {
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
            
            LifeContextsDisplayView(contextRids: quote.contextRids)
            
            if let data = quote.mediaDetailsData, let details = try? JSONDecoder().decode(MediaDetails.self, from: data) {
                DataMediaItemPillView(itemId: details.itemId, mediaDetails: details)
            }
        }
        .padding()
        .background(Color.primaryBackground)
        .cornerRadius(12)
    }
}
