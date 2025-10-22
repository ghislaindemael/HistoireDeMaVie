//
//  BaseDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.10.2025.
//


import Foundation
import SwiftData
import SwiftUI

@MainActor
class BaseDetailSheetViewModel<ModelType: EditableModel, EditorType: EditorProtocol>: ObservableObject
where ModelType == EditorType.Model
{
    @Published var editor: EditorType
    private var model: ModelType
    let modelContext: ModelContext

    init(model: ModelType, modelContext: ModelContext) {
        self.model = model
        self.editor = EditorType(from: model)
        self.modelContext = modelContext
    }

    func onDone() {
        editor.apply(to: model)
        model.markAsModified()

        do {
            try modelContext.save()
            print("✅ \(ModelType.self) \(model.id) saved to context.")
        } catch {
            print("❌ Failed to save \(ModelType.self) to context: \(error)")
        }
    }

}
