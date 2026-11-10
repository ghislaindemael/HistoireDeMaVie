//
//  DateDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//

import SwiftUI

struct DateDisplayView: View {
    let date: Date
    var selectedDate: Date = .now
    var timeZone: TimeZone? = nil
    var showOffsetBadge: Bool = true
    
    var body: some View {
        HStack(spacing: 3) {
            HStack(spacing: 0) {
                if let dayString = TimeZoneFormatUtils.displayDateIfNeeded(for: date, comparedTo: selectedDate, in: timeZone) {
                    Text("\(dayString) ")
                }
                Text(TimeZoneFormatUtils.formatTime(date, in: timeZone))
            }
            
            if showOffsetBadge, let badge = TimeZoneFormatUtils.offsetBadgeString(for: date, in: timeZone) {
                TimeZoneBadgeView(badge: badge)
            }
        }
    }
}
