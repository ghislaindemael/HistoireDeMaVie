//
//  TimeUtils.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import Foundation

func combineDateTime(date: Date, timeString: String) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    
    let timeParts = timeString.split(separator: ":").compactMap { Int($0) }
    guard timeParts.count == 3 else {
        return date // fallback: just the date without time
    }
    
    var combinedComponents = DateComponents()
    combinedComponents.year = dateComponents.year
    combinedComponents.month = dateComponents.month
    combinedComponents.day = dateComponents.day
    combinedComponents.hour = timeParts[0]
    combinedComponents.minute = timeParts[1]
    combinedComponents.second = timeParts[2]
    
    return calendar.date(from: combinedComponents) ?? date
}
