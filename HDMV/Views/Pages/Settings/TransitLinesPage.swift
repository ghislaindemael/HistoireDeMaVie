//
//  TransitLinesPage.swift
//  HDMV
//

import SwiftUI
import SwiftData

struct TransitLinesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel = TransitLinesPageViewModel()
    @State private var showingAddAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Cached Lines") {
                    if viewModel.transitLines.isEmpty {
                        Text("No lines found. Pull to sync from DB.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.transitLines) { line in
                            VStack(alignment: .leading) {
                                Text(line.name)
                                    .font(.headline)
                                Text("\(line.stops?.count ?? 0) stops")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Transit Lines")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { showingAddAlert = true },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .alert("Not Allowed", isPresented: $showingAddAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Transit Lines must be configured and managed via the web app.")
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
