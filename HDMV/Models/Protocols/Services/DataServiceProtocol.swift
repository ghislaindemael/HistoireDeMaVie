//
//  CatalogueServiceProtocol.swift
//  HDMV
//
//  Created by Ghislain Demael on 13.10.2025.
//


import Foundation

protocol DataServiceProtocol {
    associatedtype DTO: Identifiable
    associatedtype Payload

    func fetch(includeArchived: Bool) async throws -> [DTO]
    func fetchForDate(date: Date) async throws -> [DTO]
    func create(payload: Payload) async throws -> DTO
    func update(rid: Int, payload: Payload) async throws -> DTO
}
