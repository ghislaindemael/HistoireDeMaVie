//
//  Date+Extensions.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import Foundation

extension Date {
    /// Returns .now if the date is today, otherwise returns 12:00 PM on this date.
    var smartCreationTime: Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return Date.now
        } else {
            // Return noon on the selected day
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: self) ?? self
        }
    }
}
