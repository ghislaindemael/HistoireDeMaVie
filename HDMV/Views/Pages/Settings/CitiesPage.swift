//
//  CitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI
import SwiftData

struct CitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel = CitiesPageViewModel()
    
    @State private var isShowingCreateSheet = false
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Filter") {
                    Picker("Country", selection: $viewModel.selectedCountry) {
                        Text("Select").tag(nil as Country?)
                        ForEach(viewModel.countries) { country in
                            Text(country.name).tag(country as Country?)
                        }
                    }
                }
                
                if viewModel.selectedCountry  != nil {
                    Section() {
                        ForEach(viewModel.filteredCities) { city in
                            CityRowView(
                                city: city,
                                onRankChanged: { newRank in
                                    viewModel.updateRank(for: city, to: newRank)
                                },
                                onCacheToggle: {
                                    viewModel.toggleCache(for: city)
                                }
                            )
    
                            .swipeActions {
                                if city.archived {
                                    Button() {
                                        viewModel.unarchiveCity(for: city)
                                    } label: {
                                        Label("Un-archive", systemImage: "archivebox.fill")
                                    }
                                    .tint(.green)
                                } else {
                                    Button(role: .destructive) {
                                        viewModel.archiveCity(for: city)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox.fill")
                                    }
                                }
                            }
                        }
                        
                    }
                } else {
                    Section {
                        Text("Please select a country")
                    }
                }
            }
            .navigationTitle("Cities")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            Task {
                                await viewModel.refreshDataFromServer()
                            }
                        }) {
                            Label(
                                "Refresh \(settings.includeArchived ? "all " : "")cities",
                                systemImage: "icloud.and.arrow.down"
                            )
                        }
                    
                        Button(action: { viewModel.cacheCities() }) {
                            Label("Re-cache cities", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        }
                        
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingCreateSheet.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                NewCitySheet(viewModel: viewModel)
            }
        }
    }
}


#Preview {
    let container: ModelContainer = {
        let schema = Schema([Country.self, City.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            
            let switzerland = Country(id: 1, slug: "ch", name: "Switzerland")
            
            container.mainContext.insert(switzerland)
            
            container.mainContext.insert(City(id: 10, slug: "geneva", name: "Geneva", rank: 2, country_id: 1))
            container.mainContext.insert(City(id: 11, slug: "aubonne", name: "Aubonne-Pizy-Montherod", rank: 1, country_id: 1, archived: true))
            container.mainContext.insert(City(id: 12, slug: "lausanne", name: "Lausanne", rank: 3, country_id: 1))

            return container
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }()
    
    CitiesPage().modelContainer(container)
}
