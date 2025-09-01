//
//  ActivitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//


import SwiftUI

struct ActivitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ActivitiesPageViewModel()
    @State private var activityToEdit: Activity?
    
    var body: some View {
        NavigationStack {
            List {
                OutlineGroup(viewModel.activityTree, children: \.optionalChildren) { activity in
                    Button(action: {
                        activityToEdit = activity
                    }) {
                        ActivityRowView(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Activities")
            .logPageToolbar(
                refreshAction: { await viewModel.syncWithServer() },
                hasLocalChanges: viewModel.hasLocalChanges,
                syncAction: { await viewModel.syncLocalChanges() },
                singleTapAction: { viewModel.createLocalActivity() },
                longPressAction: {}
            )
            .sheet(item: $activityToEdit) { activity in
                ActivityDetailSheet(activity: activity, viewModel: viewModel)
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .syncingOverlay(viewModel.isLoading)
        }
    }
}
