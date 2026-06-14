import SwiftUI
import SwiftData

struct DataFoodOptionSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataFoodOption.name) private var allOptions: [DataFoodOption]
    
    let onSelect: (DataFoodOption) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allOptions) { option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(option.name)
                                    .font(.headline)
                                Text(option.slug)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(option.typeRaw.capitalized)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
