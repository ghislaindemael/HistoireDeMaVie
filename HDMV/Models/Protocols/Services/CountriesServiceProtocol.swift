//
//  CountriesServiceProtocol.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//


import Foundation

protocol CountriesServiceProtocol {
    func fetchCountries() async throws -> [CountryDTO]
    func createCountry(payload: NewCountryPayload) async throws -> CountryDTO
    func updateCacheStatus(for country: Country) async throws
    func archiveCountry(country: Country) async throws
    func unarchiveCountry(country: Country) async throws
}
