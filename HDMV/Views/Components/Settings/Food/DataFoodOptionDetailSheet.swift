import SwiftUI
import SwiftData

struct DataFoodOptionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var item: DataFoodOption
    var modelContext: ModelContext
    
    @StateObject var viewModel: DataFoodOptionDetailSheetViewModel
    
    init(item: DataFoodOption, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._viewModel = StateObject(wrappedValue: DataFoodOptionDetailSheetViewModel(model: item, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                        .autocapitalization(.none)
                }
                
                Section("Type") {
                    Picker("Type", selection: $viewModel.editor.typeRaw) {
                        Text("Boolean").tag("boolean")
                        Text("Integer").tag("integer")
                        Text("Decimal").tag("decimal")
                        Text("Text").tag("text")
                        Text("Dropdown").tag("dropdown")
                    }
                    Toggle("Is Required", isOn: $viewModel.editor.isRequired)
                }
                
                UsageSectionView(isCached: $viewModel.editor.cache, isArchived: $viewModel.editor.archived)
            }
            .navigationTitle("Edit Option")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
}
