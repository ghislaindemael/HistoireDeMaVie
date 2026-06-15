import SwiftUI
import SwiftData

struct HierarchySectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    let model: any LogModel
    let hasParent: Bool
    let onRemoveFromParent: () -> Void
    
    @State private var justCreatedTrip = false
    @State private var justCreatedInstance = false
    
    var body: some View {
        Section("Hierarchy") {
            Button("Remove from Parent", role: .destructive) {
                onRemoveFromParent()
            }
            .disabled(!hasParent)
            if let parentModel = model as? any ParentModel {
                Button(action: {
                    withAnimation {
                        createChildTrip(parent: parentModel)
                        justCreatedTrip = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { justCreatedTrip = false }
                    }
                }) {
                    HStack {
                        Text("Create Child Trip")
                        if justCreatedTrip {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                Button(action: {
                    withAnimation {
                        createChildInstance(parent: parentModel)
                        justCreatedInstance = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { justCreatedInstance = false }
                    }
                }) {
                    HStack {
                        Text("Create Child Instance")
                        if justCreatedInstance {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
    
    private func createChildInstance(parent: any ParentModel) {
        ActivityInstance.createChild(in: modelContext, parent: parent, filterDate: parent.timeStart)
    }
    
    private func createChildTrip(parent: any ParentModel) {
        Trip.create(in: modelContext, parent: parent, filterDate: parent.timeStart)
    }
}
