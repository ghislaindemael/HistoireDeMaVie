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
        predicate: #Predicate { $0.cache == true },
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
                }
            }
            .navigationTitle("Activity Options")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createOption() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $optionToEdit) { option in
                DataActivityOptionDetailSheet(option: option, modelContext: modelContext)
            }
        }
    }
}
