//
//  CountryRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

struct CountryRowView: View {
    
    let country: Country
    var onToggle: ((Country) -> Void)? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                UnsettableTextView(
                    text: country.name,
                    font: .title3.bold(),
                    isItalicized: country.archived
                )
                if let tzId = country.effectiveTimeZoneIdentifier {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text(tzId)
                        if let badge = TimeZoneFormatUtils.offsetBadgeString(for: .now, in: country.resolvedTimeZone) {
                            Text(badge)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CatalogueRowControlsView(model: country, onToggle: onToggle)
        }
    }
        
}
