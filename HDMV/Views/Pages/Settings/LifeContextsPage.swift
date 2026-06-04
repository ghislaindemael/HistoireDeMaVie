//
//  LifeContextsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

struct LifeContextsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = LifeContextsPageViewModel()
    
    var body: some View {
        NavigationStack {
            GenericTreePageView(
                title: "Life Contexts",
                items: viewModel.contexts,
                childrenKeyPath: \.optionalChildren,
                isLoading: viewModel.isLoading,
                onRefresh: { await viewModel.refreshFromServer() },
                onSync: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createContext() },
                rowContent: { context in
                    LifeContextRowView(context: context) { c in
                        viewModel.updateModel(c) { $0.cache.toggle() }
                    }
                },
                sheetContent: { context in
                    LifeContextDetailSheet(lifeContext: context, modelContext: modelContext)
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
