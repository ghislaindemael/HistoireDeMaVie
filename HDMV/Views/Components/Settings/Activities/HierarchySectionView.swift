import SwiftUI
import SwiftData

struct HierarchySectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    let model: any LogModel
    let hasParent: Bool
    let onRemoveFromParent: () -> Void
    
    var body: some View {
        Section("Hierarchy") {
            Button("Remove from Parent", role: .destructive) {
                onRemoveFromParent()
            }
            .disabled(!hasParent)
            if let parentModel = model as? any ParentModel {
                Button("Create Child Trip") {
                    createChildTrip(parent: parentModel)
                }
                Button("Create Child Instance") {
                    createChildInstance(parent: parentModel)
                }
            }
        }
    }
    
    private func createChildInstance(parent: any ParentModel) {
        let childDate = parent.timeStart.addingTimeInterval(1)
        var child = ActivityInstance(timeStart: childDate)
        if let end = parent.timeEnd {
            child.timeEnd = end.addingTimeInterval(-1)
        }
        child.setParent(parent)
        modelContext.insert(child)
        try? modelContext.save()
    }
    
    private func createChildTrip(parent: any ParentModel) {
        let childDate = parent.timeStart.addingTimeInterval(1)
        var child = Trip(timeStart: childDate)
        if let end = parent.timeEnd {
            child.timeEnd = end.addingTimeInterval(-1)
        }
        child.setParent(parent)
        modelContext.insert(child)
        try? modelContext.save()
    }
}
