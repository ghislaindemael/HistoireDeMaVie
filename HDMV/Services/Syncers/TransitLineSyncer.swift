//
//  TransitLineSyncer.swift
//  HDMV
//

import Foundation
import SwiftData

@MainActor
final class TransitLineSyncer: BaseSyncer<TransitLine, TransitLineDTO, TransitLinePayload> {
    
    private let transitLinesService = TransitLinesService()
    
    override func fetchRemoteModels(date: Date?) async throws -> [TransitLineDTO] {
        return try await transitLinesService.fetch(includeArchived: false)
    }
    
    override func createOnServer(payload: TransitLinePayload) async throws -> TransitLineDTO {
        fatalError("Creation of TransitLines from within the app is not allowed. Configure via web app.")
    }
    
    override func updateOnServer(rid: Int, payload: TransitLinePayload) async throws -> TransitLineDTO {
        fatalError("Editing of TransitLines from within the app is not allowed. Configure via web app.")
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("Deletion of TransitLines from within the app is not allowed. Configure via web app.")
    }
    
    override func resolveRelationships() throws {
        // No direct SwiftData relationships to resolve for TransitLine currently
    }
}
