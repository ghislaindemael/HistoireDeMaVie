//
//  LifeEventRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct LifeEventRowView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = SettingsStore.shared
    
    let event: LifeEvent
    let selectedDate: Date
    
    init(
        event: LifeEvent,
        selectedDate: Date,
    ) {
        self.event = event
        self.selectedDate = selectedDate
    }
    
    
    var body: some View {
        VStack {
            basicsSection
            detailsSection
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryBackground)
        )
        
    }
    
    @ViewBuilder
    private var basicsSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(alignment: .leading) {
                HStack() {
                    IconView(
                        iconString: event.type.icon,
                        size: 30,
                        tint: event.type == .unset ? .red : .primary,
                    )
                    
                    VStack(alignment: .leading) {
                        Text(event.type.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(event.type != .unset ? Color.primary : Color.red)
                        HStack(spacing: 4) {
                            if let startDateString = displayDateIfNeeded(for: event.timeStart, comparedTo: selectedDate) {
                                Text("\(startDateString) ")
                            }
                            Text(event.timeStart, style: .time)
                            
                            Image(systemName: "arrow.right")
                            
                            if let timeEnd = event.timeEnd {
                                if let endDateString = displayDateIfNeeded(for: timeEnd, comparedTo: event.timeStart) {
                                    Text("\(endDateString) ")
                                }
                                Text(timeEnd, style: .time)
                            }
                        }
                        .font(.subheadline)
                        
                    }
                    Spacer()
                    
                }
                
            }
            .padding(.vertical, 4)
            
            SyncStatusIndicator(status: event.syncStatus)
                .padding([.top, .trailing], 0)
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack {
            
            if let details = event.details, !details.isEmpty {
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
            

           // TODO: Show metrics sliders
            
        }
    }
        
    private func displayDateIfNeeded(for date: Date, comparedTo selectedDate: Date) -> String? {
        let calendar = Calendar.current
        if !calendar.isDate(date, inSameDayAs: selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
        return nil
    }
    
}
