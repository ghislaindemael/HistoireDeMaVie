//
//  TitleLabel.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.11.2025.
//


import SwiftUI

struct TitleLabel: View {
    let title: String
    
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Text(settings.planningMode ? "Planning \(title)" : title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(settings.planningMode ? .orange : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 4)
    }
}
