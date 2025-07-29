//
//  CountryRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

struct CountryRowView: View {
    @Bindable var country: Country
    
    let onCacheToggle: () -> Void
    
    var body: some View {
        ViewThatFits {
            horizontalLayout
            verticalLayout
        }
        .padding(.vertical, 1)
    }
    
    /// The ideal layout for wider screens: everything on a single line.
    private var horizontalLayout: some View {
        HStack {
            Text(country.name)
                .font(.title3.bold())
                .lineLimit(1)
            
            Spacer()
            controls
        }
    }
    
    /// The fallback layout for narrower screens: controls wrap to a new line.
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(country.name)
                .font(.title3.bold())
            
            HStack {
                controls
                Spacer()
            }
        }
    }
    
    /// A shared view for the controls to avoid code duplication.
    private var controls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Cache")
                    .lineLimit(1)
                Toggle("Cache", isOn: $country.cache)
                    .labelsHidden()
                    .scaleEffect(0.9)
                    .onChange(of: country.cache) {
                        onCacheToggle()
                    }
            }
        }
    }
}
