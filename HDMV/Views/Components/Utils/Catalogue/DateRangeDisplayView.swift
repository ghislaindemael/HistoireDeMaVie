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

    var body: some View {
        HStack(spacing: 4) {
            DateDisplayView(date: startDate, selectedDate: selectedDate)
            Image(systemName: "arrow.right")

            if let end = endDate {
                DateDisplayView(date: end, selectedDate: selectedDate)
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
