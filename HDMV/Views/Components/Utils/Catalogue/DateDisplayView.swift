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
    
    var body: some View {
        HStack(spacing: 0) {
            if let dayString = displayDateIfNeeded(for: date, comparedTo: selectedDate) {
                Text("\(dayString) ")
            }
            Text(date, style: .time)
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
