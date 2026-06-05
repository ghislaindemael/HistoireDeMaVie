//
//  MediaDetailsEditView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI
import SwiftData



struct MediaDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    
    @Query(sort: \DataMediaItem.name) private var allMediaItems: [DataMediaItem]
    
    @Query(filter: #Predicate<DataMediaItem> { $0.parentRid == nil }, sort: \.name)
    private var rootMediaItems: [DataMediaItem]
    
    @State private var editingIndex: Int = 0
    @State private var isShowingSheet = false
    
    var body: some View {
        Group {
            if let mediaList = metadata?.media, !mediaList.isEmpty {
                ForEach(mediaList.indices, id: \.self) { index in
                    let mediaDetail = mediaList[index]
                    let item = allMediaItems.first(where: { $0.rid == mediaDetail.itemId })
                    
                    Button {
                        editingIndex = index
                        isShowingSheet = true
                    } label: {
                        HStack {
                            if let icon = item?.icon {
                                IconView(iconString: icon)
                            } else {
                                IconView(iconString: "questionmark.circle", tint: .secondary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(item?.name ?? "Select an Item...")
                                    .font(.headline)
                                    .foregroundColor(item == nil ? .secondary : .primary)
                                
                                if let progress = mediaDetail.progress, !progress.isEmpty {
                                    Text(progress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeMedia(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } else {
                Text("No media linked.")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                addBlankMedia()
            }) {
                Label("Add Cultural Item", systemImage: "plus")
            }
            .sheet(isPresented: $isShowingSheet) {
                MediaItemEditorSheet(
                    metadata: $metadata,
                    index: editingIndex,
                    allMediaItems: allMediaItems,
                    rootMediaItems: rootMediaItems
                )
            }
        }
    }
    
    private func addBlankMedia() {
        if metadata == nil {
            metadata = ActivityDetails()
        }
        if metadata?.media == nil {
            metadata?.media = []
        }
        // Use itemId 0 or an invalid ID to represent a blank unselected item
        metadata?.media?.append(MediaDetails(itemId: -1, progress: nil))
    }
    
    private func removeMedia(at index: Int) {
        metadata?.media?.remove(at: index)
        if metadata?.media?.isEmpty == true {
            metadata?.media = nil
        }
    }
}



struct MediaItemEditorSheet: View {
    @Binding var metadata: ActivityDetails?
    let index: Int
    
    let allMediaItems: [DataMediaItem]
    let rootMediaItems: [DataMediaItem]
    
    @Environment(\.dismiss) private var dismiss
    @State private var localProgress: String = ""
    @State private var localItemId: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item") {
                    NavigationLink(destination: GenericTreeSelectorView(
                        items: rootMediaItems,
                        childrenKeyPath: \.optionalChildren,
                        selection: Binding(
                            get: { allMediaItems.first(where: { $0.rid == localItemId }) },
                            set: { if let newRid = $0?.rid { localItemId = newRid } }
                        ),
                        title: "Select Item",
                        noneButtonText: "Cancel"
                    )) {
                        HStack {
                            Text("Cultural Item")
                            Spacer()
                            if let item = allMediaItems.first(where: { $0.rid == localItemId }) {
                                Text(item.name).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Progress") {
                    TextEditor(text: $localProgress)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Linked Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let detail = metadata?.media?[safe: index] {
                    localProgress = detail.progress ?? ""
                    localItemId = detail.itemId
                }
            }
        }
    }
    
    private func saveChanges() {
        if metadata?.media != nil && index < (metadata?.media?.count ?? 0) {
            metadata?.media?[index].progress = localProgress.isEmpty ? nil : localProgress
            metadata?.media?[index].itemId = localItemId
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

