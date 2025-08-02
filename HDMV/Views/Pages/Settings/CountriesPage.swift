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
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel = CountriesPageViewModel()
    
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                countriesList
            }
            .navigationTitle("Countries")
            .standardConfigPageToolbar(
                refreshAction: viewModel.fetchFromServer,
                cacheAction: viewModel.cacheCountries,
                isShowingAddSheet: $isShowingAddSheet
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext, settings: settings)
            }
            .sheet(isPresented: $isShowingAddSheet) {
                NewCountrySheet(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private var countriesList: some View {
        Section() {
            ForEach(viewModel.countries) { country in
                CountryRowView(
                    country: country,
                    onCacheToggle: {
                        viewModel.updateCache(for: country)
                    }
                )
                .swipeActions {
                    if country.archived {
                        Button(action: {
                            viewModel.unarchiveCountry(for: country)
                        }) {
                            Label("Un-archive", systemImage: "archivebox.fill")
                        }
                        .tint(.green)
                    } else {
                        Button(role: .destructive, action: {
                            viewModel.archiveCountry(for: country)
                        }) {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                    }
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
            
            let switzerland = Country(id: 1, slug: "ch", name: "Switzerland")
            container.mainContext.insert(switzerland)
            return container
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }()
    
    CountriesPage().modelContainer(container)
}
