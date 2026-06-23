//
//  GenericFilterControlView.swift
//  HDMV
//
//  Created for shared timeline filters
//

import SwiftUI

struct GenericFilterControlView<CustomContent: View>: View {
    @Binding var filterMode: TimelineFilterMode
    @Binding var filterDate: Date
    @Binding var filterStartDate: Date
    @Binding var filterEndDate: Date
    
    let advancedFilterLabel: String
    @ViewBuilder let advancedFilterContent: CustomContent
    
    @ObservedObject var settings = SettingsStore.shared
    
    private var currentTabViewHeight: CGFloat {
        switch filterMode {
            case .daily:
                return 33
            case .advanced:
                return 140
        }
    }
    
    private var byDateTab: some View {
        VStack {
            LockedDatePickerView(selection: $filterDate)
                .padding()
        }
        .tag(TimelineFilterMode.daily)
    }
    
    private var advancedTab: some View {
        VStack {
            DatePicker("From", selection: $filterStartDate, displayedComponents: .date)
            DatePicker("To", selection: $filterEndDate, displayedComponents: .date)
            
            HStack {
                Text(advancedFilterLabel)
                Spacer()
                advancedFilterContent
            }
        }
        .padding()
        .tag(TimelineFilterMode.advanced)
    }
    
    var body: some View {
        TabView(selection: $filterMode) {
            byDateTab
            advancedTab
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: currentTabViewHeight)
        .animation(.easeInOut(duration: 0.25), value: filterMode)
    }
}
