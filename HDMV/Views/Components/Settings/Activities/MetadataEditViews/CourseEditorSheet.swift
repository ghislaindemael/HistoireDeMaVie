import SwiftUI

struct CourseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let course: CourseType
    @Binding var consumedItems: [ComposedFood]
    
    @State private var showingItemSelector = false
    @State private var itemToEdit: ComposedFood? = nil
    
    var body: some View {
        NavigationStack {
            List {
                let itemsInCourse = consumedItems.filter { $0.course == course }
                
                ForEach(itemsInCourse) { item in
                    Button {
                        itemToEdit = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.rawText ?? "Unknown Food")
                                    .foregroundColor(.primary)
                                
                                if let qty = item.quantity {
                                    Text(String(format: "%.1f", qty) + " " + (item.unit?.rawValue ?? ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                        }
                    }
                }
                .onDelete { indices in
                    let idsToDelete = indices.map { itemsInCourse[$0].id }
                    consumedItems.removeAll { idsToDelete.contains($0.id) }
                }
                
                Button(action: {
                    showingItemSelector = true
                }) {
                    Label("Add Food", systemImage: "plus.circle")
                }
            }
            .navigationTitle(course.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingItemSelector) {
                FoodItemSelectorSheet(course: course) { newItem in
                    consumedItems.append(newItem)
                }
            }
            .sheet(item: $itemToEdit) { compItem in
                if let idx = consumedItems.firstIndex(where: { $0.id == compItem.id }) {
                    ComposedFoodEditorSheet(item: $consumedItems[idx])
                } else {
                    Text("Error: Item not found")
                }
            }
        }
    }
}
