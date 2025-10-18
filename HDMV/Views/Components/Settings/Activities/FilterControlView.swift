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
                return 40
            case .byActivity:
                return 140
        }
    }
    
    
    private var byDateTab: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $viewModel.filterDate,
                displayedComponents: .date
            )
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
