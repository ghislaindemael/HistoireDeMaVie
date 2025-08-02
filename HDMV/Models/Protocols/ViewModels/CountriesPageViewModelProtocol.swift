//
//  CountriesPageViewModelProtocol.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//

import SwiftData

@MainActor
protocol CountriesPageViewModelProtocol: AnyObject {
    
    var isLoading: Bool { get set }
    var countries: [Country] { get set }
    
    func setup(modelContext: ModelContext, settings: SettingsStore)
    func fetchFromCache()
    func fetchFromServer() async
    func cacheCountries()
    func createCountry(payload: NewCountryPayload) async
    func updateCache(for country: Country)
    func archiveCountry(for country: Country)
    func unarchiveCountry(for country: Country)
    
}
