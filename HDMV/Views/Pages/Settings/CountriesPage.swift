//
//  CountriesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//

import SwiftUI
import SwiftData

struct CountriesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CountriesPageViewModel()
    
    @State private var countryToEdit: Country?
    
    var body: some View {
        NavigationStack {
            Form {
                countriesList
            }
            .navigationTitle("Countries")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createCountry() },
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $countryToEdit) { country in
                //TODO: Add country editor sheet
            }
        }
    }
    
    @ViewBuilder
    private var countriesList: some View {
        Section("") {
            ForEach(viewModel.items) { country in
                CountryRowView(country: country) { c in
                    withAnimation(.snappy) {
                        viewModel.updateModel(c) { $0.cache.toggle() }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    viewModel.deleteItem(viewModel.items[index])
                }
            }
        }
    }
}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([Country.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            
            let switzerland = Country(slug: "ch", name: "Switzerland")
            container.mainContext.insert(switzerland)
            return container
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }()
    
    CountriesPage().modelContainer(container)
}
