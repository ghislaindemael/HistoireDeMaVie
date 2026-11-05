//
//  DateRangeDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//

import SwiftUI

struct DateRangeDisplayView: View {
    let startDate: Date
    let endDate: Date?
    var selectedDate: Date = .now
    var startTimeZone: TimeZone? = nil
    var endTimeZone: TimeZone? = nil

    var body: some View {
        let effectiveEndTZ = endTimeZone ?? startTimeZone
        let hasDistinctEnd = (endDate != nil && endDate != startDate)
        let startBadge = TimeZoneFormatUtils.offsetBadgeString(for: startDate, in: startTimeZone)
        let endBadge = hasDistinctEnd ? TimeZoneFormatUtils.offsetBadgeString(for: endDate!, in: effectiveEndTZ) : nil
        
        // If start and end share the exact same offset badge, only display it once at the end of the range
        let showStartBadge = !hasDistinctEnd || (startBadge != endBadge)
        
        HStack(spacing: 4) {
            DateDisplayView(
                date: startDate,
                selectedDate: selectedDate,
                timeZone: startTimeZone,
                showOffsetBadge: showStartBadge
            )
            
            if let end = endDate, end != startDate {
                Image(systemName: "arrow.right")
                DateDisplayView(
                    date: end,
                    selectedDate: selectedDate,
                    timeZone: effectiveEndTZ,
                    showOffsetBadge: true
                )
            } else if endDate == nil {
                Image(systemName: "arrow.right")
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
