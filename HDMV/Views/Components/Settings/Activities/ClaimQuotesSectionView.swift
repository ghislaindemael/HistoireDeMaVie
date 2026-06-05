//
//  ClaimQuotesSectionView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct ClaimQuotesSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unclaimedQuotes: [Quote]
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        let endBoundDate = parent.timeEnd ?? Date.now
        let startOfEndBoundDay = calendar.startOfDay(for: endBoundDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfEndBoundDay) ?? Date.distantFuture
        
        let predicate = #Predicate<Quote> { quote in
            quote.parentInstanceRid == nil &&
            quote.parentTripRid == nil &&
            quote.timeStart >= startOfDay &&
            quote.timeStart < endOfDay
        }
        
        _unclaimedQuotes = Query(filter: predicate, sort: \.timeStart)
    }
    
    private func claim(quote: Quote) {
        var mutableQuote = quote
        mutableQuote.setParent(parent)
        mutableQuote.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        Section("Claim Quotes") {
            if unclaimedQuotes.isEmpty {
                Text("No unclaimed quotes available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(unclaimedQuotes) { quote in
                    QuoteRowView(quote: quote)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(quote: quote)
                        }
                }
            }
        }
    }
}
