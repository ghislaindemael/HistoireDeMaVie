//
//  QuoteDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct QuoteDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: QuoteDetailSheetViewModel
    
    let quote: Quote
    
    init(
        quote: Quote,
        modelContext: ModelContext
    ) {
        self.quote = quote
        _viewModel = StateObject(wrappedValue: QuoteDetailSheetViewModel(
            model: quote,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                TimeSection(editor: $viewModel.editor, hideEndTime: true)
                
                Section("Details") {
                    TextField("Quote Text", text: $viewModel.editor.text, axis: .vertical)
                        .lineLimit(3...)
                    
                    TextField("Author Name", text: Binding(
                        get: { viewModel.editor.authorString ?? "" },
                        set: { viewModel.editor.authorString = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Context", text: Binding(
                        get: { viewModel.editor.context ?? "" },
                        set: { viewModel.editor.context = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section("Media & People") {
                    PersonSelectorView(selectedPerson: $viewModel.editor.person)
                    
                    DataMediaItemSelectorView(selectedItem: $viewModel.editor.mediaItem)
                    
                    if viewModel.editor.mediaItem != nil {
                        TextField("Media Progress (e.g. Chapter 4, Page 42)", text: Binding(
                            get: { viewModel.editor.mediaProgress ?? "" },
                            set: { viewModel.editor.mediaProgress = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }
                
                HierarchySectionView(
                    model: quote,
                    hasParent: !viewModel.editor.hasNoParent(),
                    onRemoveFromParent: {
                        viewModel.editor.clearParents()
                    }
                )

            }
            .navigationTitle("Edit Quote")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
}
