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
    
    @State private var selectedMediaItem: DataMediaItem?
    @Query private var allMediaItems: [DataMediaItem]
    
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
                    
                    DataMediaItemSelectorView(selectedItem: $selectedMediaItem)
                        .onChange(of: selectedMediaItem) { _, newValue in
                            if let item = newValue, let id = item.rid {
                                if viewModel.editor.mediaDetails != nil {
                                    viewModel.editor.mediaDetails!.itemId = id
                                } else {
                                    viewModel.editor.mediaDetails = MediaDetails(itemId: id)
                                }
                            } else {
                                viewModel.editor.mediaDetails = nil
                            }
                        }
                    
                    if viewModel.editor.mediaDetails != nil {
                        HStack {
                            TextField("Season", value: Binding(
                                get: { viewModel.editor.mediaDetails?.season },
                                set: { viewModel.editor.mediaDetails?.season = $0 }
                            ), format: .number).keyboardType(.numberPad)
                            Divider()
                            TextField("Episode", value: Binding(
                                get: { viewModel.editor.mediaDetails?.episode },
                                set: { viewModel.editor.mediaDetails?.episode = $0 }
                            ), format: .number).keyboardType(.numberPad)
                        }
                        TextField("Tome / Volume", value: Binding(
                            get: { viewModel.editor.mediaDetails?.tome },
                            set: { viewModel.editor.mediaDetails?.tome = $0 }
                        ), format: .number).keyboardType(.numberPad)
                        
                        HStack {
                            TextField("Completion %", value: Binding(
                                get: { viewModel.editor.mediaDetails?.percentage },
                                set: { viewModel.editor.mediaDetails?.percentage = $0 }
                            ), format: .number).keyboardType(.numberPad)
                            Divider()
                            TextField("Time (mins)", value: Binding(
                                get: { viewModel.editor.mediaDetails?.time },
                                set: { viewModel.editor.mediaDetails?.time = $0 }
                            ), format: .number).keyboardType(.numberPad)
                        }
                        
                        TextField("Custom Notes / Progress", text: Binding(
                            get: { viewModel.editor.mediaDetails?.progress ?? "" },
                            set: { viewModel.editor.mediaDetails?.progress = $0.isEmpty ? nil : $0 }
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
            .onAppear {
                if let itemId = viewModel.editor.mediaDetails?.itemId {
                    selectedMediaItem = allMediaItems.first { $0.rid == itemId }
                }
            }
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
}
