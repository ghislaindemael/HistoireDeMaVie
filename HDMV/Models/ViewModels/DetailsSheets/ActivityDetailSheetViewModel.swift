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
class ActivityDetailSheetViewModel: ObservableObject {
    @Published var editor: ActivityEditor

    private var activity: Activity
    private let modelContext: ModelContext
    
    init(activity: Activity, modelContext: ModelContext) {
        self.activity = activity
        self.editor = ActivityEditor(from: activity)
        self.modelContext = modelContext
    }

    func onDone() {
        editor.apply(to: activity)
        activity.markAsModified()
        
        do {
            try modelContext.save()
            print("✅ Activity \(activity.id) saved to context.")
        } catch {
            print("❌ Failed to save place to context: \(error)")
        }
    }
}
