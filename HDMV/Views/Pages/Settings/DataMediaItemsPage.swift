//
//  DataMediaItemsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

struct DataMediaItemsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataMediaItemsPageViewModel()
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Media Items",
                items: viewModel.items,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createItem() },
                rowContent: { item in
                    DataMediaItemRowView(item: item) { c in
                        viewModel.updateModel(c) { $0.cache.toggle() }
                    }
                },
                sheetContent: { item in
                    DataMediaItemDetailSheet(item: item, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
