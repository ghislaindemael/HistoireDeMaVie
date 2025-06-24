//
//  DateFormatter+Extensions.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//


import Foundation

public extension DateFormatter {
    
    /// A static formatter for displaying time in HH:mm:ss format.
    /// This is a computed static property to ensure thread safety, as formatters are not thread-safe.
    /// By creating a new instance for each call, you avoid potential crashes in multi-threaded environments.
    static var timeOnly: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    // You can add other reusable formatters here as well.
    // For example, a formatter for just the date:
    
    /// A static formatter for displaying a medium-style date (e.g., "Jun 24, 2025").
    static var dateOnly: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}