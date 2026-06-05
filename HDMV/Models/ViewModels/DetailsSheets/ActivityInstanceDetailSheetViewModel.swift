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
    
    override func onDone() {
        var cleanDetails = editor.decodedActivityDetails
        
        if let currentMedia = cleanDetails?.media {
            let filteredMedia = currentMedia.filter { $0.itemId != -1 }
            cleanDetails?.media = filteredMedia.isEmpty ? nil : filteredMedia
        }
        
        editor.decodedActivityDetails = cleanDetails
        
        super.onDone()
    }
}
