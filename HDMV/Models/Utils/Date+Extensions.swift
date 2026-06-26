//
//  Date+Extensions.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import Foundation

extension Date {
    /// Returns .now if the date is today (or yesterday between 00:00 and 03:00), otherwise returns 12:00 PM on this date.
    var smartCreationTime: Date {
        let calendar = Calendar.current
        let now = Date.now
        
        if calendar.isDateInToday(self) {
            return now
        }
        
        if calendar.isDateInYesterday(self) {
            let hour = calendar.component(.hour, from: now)
            if hour < 3 && SettingsStore.shared.appMode == .live {
                return now
            }
        }
        
        // Return noon on the selected day
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: self) ?? self
    }
}
