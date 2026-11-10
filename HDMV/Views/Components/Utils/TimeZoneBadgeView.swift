//
//  TimeZoneBadgeView.swift
//  HDMV
//

import SwiftUI

struct TimeZoneBadgeView: View {
    let badge: String
    
    var body: some View {
        Text(badge)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondaryBackground)
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }
}
