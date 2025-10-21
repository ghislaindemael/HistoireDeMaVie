//
//  InteractionDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 21.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class InteractionDetailSheetViewModel: ObservableObject {
    
    @Published var editor: InteractionEditor
    
    private var modelContext: ModelContext
    private var interaction: Interaction
    
    // MARK: Initialization
            
    init(interaction: Interaction, modelContext: ModelContext) {
        self.interaction = interaction
        self.editor = InteractionEditor(interaction: interaction)
        self.modelContext = modelContext
    }

    func onDone(completion: @escaping () -> Void) {
        editor.apply(to: interaction)
        interaction.markAsModified()
        
        do {
            try modelContext.save()
            completion()
        } catch {
            print("❌ Failed to save Trip: \(error)")
        }
    }

    
}

