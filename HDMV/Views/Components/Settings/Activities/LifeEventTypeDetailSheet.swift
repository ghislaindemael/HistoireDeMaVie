import SwiftUI
import SwiftData

struct LifeEventTypeDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: LifeEventTypeDetailSheetViewModel
    
    @Query var typesTree: [LifeEventType]

    init(type: LifeEventType, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: LifeEventTypeDetailSheetViewModel(
            model: type,
            modelContext: modelContext
        ))
        let predicate = #Predicate<LifeEventType> { $0.parent == nil }
        _typesTree = Query(filter: predicate, sort: \.name)
    }
    
        
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        TextField("Icon", text: $viewModel.editor.icon.orEmpty())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Spacer()
                        IconView(iconString: viewModel.editor.icon ?? "")
                    }
                    NavigationLink(destination: ParentLifeEventTypeSelector(
                        types: typesTree,
                        selectedParent: $viewModel.editor.parent)
                    ) {
                        HStack {
                            Text("Parent Type")
                            Spacer()
                        }
                    }
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
                if viewModel.editor.parent != nil || viewModel.editor.parentRid != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parent = nil
                            viewModel.editor.parentRid = nil
                        }
                    }
                }
                
            }
            .navigationTitle("Edit Life Event Type")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
}
