//
//  ActivityInstanceDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct ActivityInstanceDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ActivityInstanceDetailSheetViewModel
    
    let instance: ActivityInstance
    
    private var selectedActivity: Activity? {
        viewModel.editor.activity
    }
    
    init(
        instance: ActivityInstance,
        modelContext: ModelContext
    ) {
        self.instance = instance
        _viewModel = StateObject(wrappedValue: ActivityInstanceDetailSheetViewModel(
            model: instance,
            modelContext: modelContext
        ))
    }
    

    var body: some View {
        NavigationView {
            Form {
                
                TimeSection(editor: $viewModel.editor)
                
                basicsSection
                detailsSection
                if let activity = selectedActivity, activity.canLogDetails() {
                    specializedDetailsSection
                }
                
                
                HierarchySectionView(
                    model: instance,
                    hasParent: !viewModel.editor.hasNoParent(),
                    onRemoveFromParent: {
                        viewModel.editor.clearParents()
                    }
                )
                
                OrphanLogItemConnector(
                    parent: instance,
                    activity: selectedActivity
                )

            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(selectedActivity?.name ?? "Edit Instance")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private func headerView(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
    
    private var basicsSection: some View {
        Section(header: headerView("Basics")) {
            NavigationLink(destination: ActivitySelectorView(
                selectedActivity: $viewModel.editor.activity
            )) {
                HStack {
                    Text("Select Activity")
                    Spacer()
                    if let activity = selectedActivity {
                        Text(activity.name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            NavigationLink {
                MultiPersonSelectorView(selectedPersons: $viewModel.editor.persons)
            } label: {
                HStack {
                    Text("Companions")
                    Spacer()
                    Text(viewModel.editor.persons.formattedNames(emptyFallback: "None"))
                        .foregroundStyle(viewModel.editor.persons.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                }
            }
            
            NavigationLink {
                MultiLifeContextSelector(selectedContexts: $viewModel.editor.contextRids)
            } label: {
                HStack {
                    Text("Contexts")
                    Spacer()
                    Text("\(viewModel.editor.contextRids.count) selected")
                        .foregroundStyle(viewModel.editor.contextRids.isEmpty ? .secondary : .primary)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        Section(header: headerView("Details")) {
            TextField("Details", text: Binding(
                get: { viewModel.editor.details ?? "" },
                set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(4...)
        }
    }
    
    @ViewBuilder
    private var specializedDetailsSection: some View {
        Group {
            if selectedActivity!.can(.log_food) {
                Section(header: headerView("Meal Details")) {
                    MealDetailsEditView(metadata: $viewModel.editor.decodedActivityDetails)
                }
            }
            
            if !selectedActivity!.cannot(.link_place) {
                Section(header: headerView("Place")) {
                    PlaceSelectorView(
                        selectedPlace: detailsPlaceBinding,
                        linkedPlaceRid: viewModel.editor.decodedActivityDetails?.place?.placeId
                    )
                }
            }
        }
    }
    
    private var detailsPlaceBinding: Binding<Place?> {
        Binding<Place?>(
            get: {
                viewModel.editor.decodedActivityDetails?.place?.place
            },
            set: { newPlace in
                if viewModel.editor.decodedActivityDetails == nil {
                    viewModel.editor.decodedActivityDetails = ActivityDetails()
                }
                if viewModel.editor.decodedActivityDetails?.place == nil {
                    viewModel.editor.decodedActivityDetails?.place = PlaceDetails()
                }
                viewModel.editor.decodedActivityDetails?.place?.place = newPlace
                viewModel.editor.decodedActivityDetails?.place?.placeId = newPlace?.rid
            }
        )
    }
    
    
}


