//
//  LifeEventDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//

import SwiftUI
import SwiftData

struct LifeEventDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: LifeEventDetailSheetViewModel
    
    let lifeEvent: LifeEvent
    
    init(
        lifeEvent: LifeEvent,
        modelContext: ModelContext
    ) {
        self.lifeEvent = lifeEvent
        _viewModel = StateObject(wrappedValue: LifeEventDetailSheetViewModel(
            model: lifeEvent,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                TimeSection(editor: $viewModel.editor)
                detailsSection
                metricSection

                if viewModel.editor.parentInstance != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parentInstance = nil
                            viewModel.editor.parentInstanceRid = nil
                        }
                    }
                }

            }
            .navigationTitle("Edit Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var detailsSection: some View {
        Section("Details") {
            Picker("Type", selection: $viewModel.editor.type) {
                ForEach(LifeEventType.allCases) { type in
                    Text(type.name).tag(type as LifeEventType)
                }
            }
            TextEditor(text: Binding(
                get: { viewModel.editor.details ?? "" },
                set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
        }
    }
    
    @ViewBuilder
    private var metricSection: some View {
        
        Section("Metrics") {
            HStack {
                Text("Importance")
                Slider(
                    value: $viewModel.editor.metrics.importance.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
            
            HStack {
                Text("Stress")
                Slider(
                    value: $viewModel.editor.metrics.stress.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
            
            HStack {
                Text("Mood")
                Slider(
                    value: $viewModel.editor.metrics.mood.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
            
            HStack {
                Text("Energy")
                Slider(
                    value: $viewModel.editor.metrics.energy.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
            
            HStack {
                Text("Engagement")
                Slider(
                    value: $viewModel.editor.metrics.engagement.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
            
            HStack {
                Text("Fatigue")
                Slider(
                    value: $viewModel.editor.metrics.fatigue.or0Double(),
                    in: 0...100,
                    step: 1
                )
            }
        }
    }

    
    
}


