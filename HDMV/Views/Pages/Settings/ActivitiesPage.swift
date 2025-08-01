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
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                OutlineGroup(viewModel.activityTree, children: \.optionalChildren) { activity in
                    HStack{
                        ActivityRowView(activity: activity)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { activity.cache },
                            set: { _ in
                                Task {
                                    await viewModel.toggleCache(for: activity)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Activities")
            .standardConfigPageToolbar(
                refreshAction: { await viewModel.fetchFromServer() },
                cacheAction: { Task { await viewModel.cacheCurrentActivities() } },
                isShowingAddSheet: $isShowingAddSheet
            )
            .sheet(isPresented: $isShowingAddSheet) {
                NewActivitySheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
