//
//  CountryRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

struct CountryRowView: View {
    
    let country: Country
    
    var body: some View {
        HStack {
            Text(country.name)
                .font(.title3.bold())
                .lineLimit(1)
            Spacer()
            SyncStatusIndicator(status: country.syncStatus)
        }
    }
        
}
