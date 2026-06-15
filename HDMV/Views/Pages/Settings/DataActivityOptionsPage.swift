//
//  DataActivityOptionsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataActivityOptionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataActivityOptionsPageViewModel()
    
    @Query(FetchDescriptor<DataActivityOption>(
        sortBy: [SortDescriptor(\.name)]))
    private var options: [DataActivityOption]
    
    @State private var optionToEdit: DataActivityOption?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("All Options") {
                    ForEach(options) { option in
                        Button(action: { optionToEdit = option }) {
                            DataActivityOptionRowView(option: option) { opt in
                                withAnimation(.snappy) {
                                    viewModel.updateModel(opt) { concreteOpt in
                                        concreteOpt.cache.toggle()
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteOptions)
                }
            }
            .navigationTitle("Activity Options")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createOption() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $optionToEdit) { option in
                DataActivityOptionDetailSheet(option: option, modelContext: modelContext)
            }
        }
    }
    
    private func deleteOptions(at offsets: IndexSet) {
        for index in offsets {
            let option = options[index]
            modelContext.delete(option)
        }
        try? modelContext.save()
    }
}
