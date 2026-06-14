//
//  FilterControlView.swift
//  HDMV
//
//  Created by Ghislain Demael on 03.09.2025.
//


import SwiftUI

struct FilterControlView: View {
    @ObservedObject var viewModel: MyActivitiesPageViewModel
    
    private var currentTabViewHeight: CGFloat {
        switch viewModel.filterMode {
            case .byDate:
                return 33
            case .byActivity:
                return 140
        }
    }
    
    
    @ObservedObject var settings = SettingsStore.shared
    
    private var byDateTab: some View {
        VStack {
            DatePicker(
                selection: $viewModel.filterDate,
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
            .padding()
        }
        .tag(MyActivitiesPageViewModel.FilterMode.byDate)
    }
    
    private var byActivityTab: some View {
        VStack {
            DatePicker("From", selection: $viewModel.filterStartDate, displayedComponents: .date)
            DatePicker("To", selection: $viewModel.filterEndDate, displayedComponents: .date)
            
            HStack {
                Text("Activity")
                Spacer()
                NavigationLink {
                    ActivitySelectorView(selectedActivity: $viewModel.filterActivity)
                } label: {
                    Text(viewModel.filterActivity?.name ?? "Select one")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .tag(MyActivitiesPageViewModel.FilterMode.byActivity)
    }
    var body: some View {
        TabView(selection: $viewModel.filterMode) {
            byDateTab
            byActivityTab
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: currentTabViewHeight)
            .animation(.easeInOut(duration: 0.25), value: viewModel.filterMode)
        
    }
}
