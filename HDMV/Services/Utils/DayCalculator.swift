//
//  DayCalculator.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import Foundation

struct DayCalculator {
    static let epochDate: Date = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        // 2001-12-15T00:00:00Z
        return formatter.date(from: "2001-12-15")!
    }()

    static let calendar = Calendar.current

    /// Calculates the day number (PK) for a given date.
    /// 2001-12-15 is Day 1.
    static func dayNumber(for date: Date) -> Int {
        let startOfEpoch = calendar.startOfDay(for: epochDate)
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        let components = calendar.dateComponents([.day], from: startOfEpoch, to: startOfTargetDate)
        
        return (components.day ?? 0) + 1
    }
}
