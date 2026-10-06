import Foundation
import SwiftData

@MainActor
class CatalogueMasterSyncer {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func pullAllCatalogues() async throws {
        // 1. Independent Core Catalogues
        try await CountrySyncer(modelContext: modelContext).pullChanges()
        try await ActivitySyncer(modelContext: modelContext).pullChanges()
        try await PersonSyncer(modelContext: modelContext).pullChanges()
        try await VehicleSyncer(modelContext: modelContext).pullChanges()
        try await LifeEventTypesSyncer(modelContext: modelContext).pullChanges()
        try await TransactionTypesSyncer(modelContext: modelContext).pullChanges()
        try await DataLogOptionSyncer(modelContext: modelContext).pullChanges()
        try await DataBankAccountsSyncer(modelContext: modelContext).pullChanges()
        try await DataMediaItemSyncer(modelContext: modelContext).pullChanges()
        
        try await DataFoodItemSyncer(modelContext: modelContext).pullChanges()
        try await DataFoodOptionSyncer(modelContext: modelContext).pullChanges()
        
        // 2. Dependent Catalogues (Geographic & Transit)
        try await CitySyncer(modelContext: modelContext).pullChanges()
        try await PlaceSyncer(modelContext: modelContext).pullChanges()
        try await TransitLineSyncer(modelContext: modelContext).pullChanges()
        try await TransitStationSyncer(modelContext: modelContext).pullChanges()
        try await TransitStopSyncer(modelContext: modelContext).pullChanges()
        
        try await DataFoodRecipeSyncer(modelContext: modelContext).pullChanges()
        
        // 3. Mapping Catalogues (Requires everything above)
        try await DataLogOptionMappingSyncer(modelContext: modelContext).pullChanges()
        try await LifeContextSyncer(modelContext: modelContext).pullChanges()
        try await DataFoodOptionMappingSyncer(modelContext: modelContext).pullChanges()
        
        // 4. Resolve Relationships (In same dependency order)
        try CitySyncer(modelContext: modelContext).resolveRelationships()
        try PlaceSyncer(modelContext: modelContext).resolveRelationships()
        try TransitStationSyncer(modelContext: modelContext).resolveRelationships()
        try TransitStopSyncer(modelContext: modelContext).resolveRelationships()
        try DataBankAccountsSyncer(modelContext: modelContext).resolveRelationships()
        try DataMediaItemSyncer(modelContext: modelContext).resolveRelationships()
        try DataFoodItemSyncer(modelContext: modelContext).resolveRelationships()
        try DataFoodRecipeSyncer(modelContext: modelContext).resolveRelationships()
        try DataLogOptionMappingSyncer(modelContext: modelContext).resolveRelationships()
        try LifeContextSyncer(modelContext: modelContext).resolveRelationships()
        try DataFoodOptionMappingSyncer(modelContext: modelContext).resolveRelationships()
        
        // Save the massive batch of resolves
        try modelContext.save()
    }
}
