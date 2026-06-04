//
//  PathDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class ActivityInstanceDetailSheetViewModel: BaseDetailSheetViewModel<ActivityInstance, ActivityInstanceEditor> {
    
    override init(
        model: ActivityInstance,
        modelContext: ModelContext
    ) {
        super.init(model: model, modelContext: modelContext)
    }
    
}
