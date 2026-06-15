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
            Text(country.name)
                .font(.title3.bold())
                .lineLimit(1)
                .italic(country.archived)
                .foregroundColor(country.archived ? .secondary : .primary)
            Spacer()
            
            if country.archived {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.medium)
            } else if let onToggle = onToggle {
                CacheToggleButton(model: country, onToggle: onToggle)
            }
            
            SyncStatusIndicator(status: country.syncStatus)
        }
    }
        
}
