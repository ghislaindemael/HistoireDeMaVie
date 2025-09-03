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
    
    
    var body: some View {
        TabView(selection: $viewModel.filterMode) {
            // MARK: - Date Filter View
            
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
            
                .padding()
                .tag(MyActivitiesPageViewModel.FilterMode.byDate)
            
            // MARK: - Activity Filter View
            VStack {
                DatePicker("From", selection: $viewModel.filterStartDate, displayedComponents: .date)
                DatePicker("To", selection: $viewModel.filterEndDate, displayedComponents: .date)
                
                HStack {
                    Text("Activity")
                    Spacer()
                    NavigationLink {
                        ActivitySelectorView(
                            activityTree: viewModel.activityTree,
                            selectedActivityId: $viewModel.filterActivityId
                        )
                    } label: {
                        
                        Text(viewModel.findActivity(by: viewModel.filterActivityId)?.name ?? "Select one")
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
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: currentTabViewHeight)
        .animation(.easeInOut(duration: 0.25), value: viewModel.filterMode)
        
    }
    
    
}
