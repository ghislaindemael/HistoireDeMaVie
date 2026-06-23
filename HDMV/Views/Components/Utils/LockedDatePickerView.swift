//
//  LockedDatePickerView.swift
//  HDMV
//
//  Created for date-bound pages
//

import SwiftUI

struct LockedDatePickerView: View {
    @Binding var selection: Date
    @ObservedObject var settings = SettingsStore.shared
    
    var body: some View {
        DatePicker(
            selection: $selection,
            displayedComponents: .date
        ) {
            HStack {
                Text("Select Date")
                if settings.appMode == .backfill {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
