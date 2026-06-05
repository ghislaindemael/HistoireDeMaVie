//
//  QuoteRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct QuoteRowView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                IconView(
                    iconString: "quote.bubble",
                    size: 24,
                    tint: .primary
                )
                Text(quote.timeStart.formatted(date: .omitted, time: .shortened))
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
            
            if let mediaItem = quote.mediaItem {
                DataMediaItemPillView(mediaItem: mediaItem, progress: quote.mediaProgress)
            }
        }
        .padding()
        .background(Color.primaryBackground)
        .cornerRadius(12)
    }
}
