//
//  OrphanLogItemConnector.swift
//  HDMV
//
//  Created by Ghislain Demael on 12.11.2025.
//


import SwiftUI
import SwiftData

struct OrphanLogItemConnector: View {
    @Environment(\.modelContext) private var modelContext
    
    let parent: any ParentModel
    let activity: Activity?
    
    let showTrips: Bool
    let showInteractions: Bool
    let showLifeEvents: Bool
    
    init(
        parent: any ParentModel,
        activity: Activity? = nil,
        showTrips: Bool? = nil,
        showInteractions: Bool? = nil,
        showLifeEvents: Bool? = nil
    ) {
        self.parent = parent
        self.activity = activity
        
        self.showTrips = showTrips ?? activity?.can(.create_trips) ?? false
        self.showInteractions = showInteractions ?? activity?.can(.create_interactions) ?? true
        self.showLifeEvents = showLifeEvents ?? true
    }

    
    var body: some View {
        tripSection
        interactionSection
        lifeEventSection
    }
    
    @ViewBuilder
    private var tripSection: some View {
        if showTrips {
            ClaimTripsSectionView(parent: parent)
        }
    }
    
    @ViewBuilder
    private var interactionSection: some View {
        if showInteractions {
            ClaimInteractionsSectionView(parent: parent)
        }
    }
    
    @ViewBuilder
    private var lifeEventSection: some View {
        if showLifeEvents {
            ClaimLifeEventsSectionView(parent: parent)
        }
    }
    
    
    
    
}
