import SwiftUI
import SwiftData

struct LifeEventTypeSelectorView: View {
    @Binding var selectedType: LifeEventType?
    @Query var typesTree: [LifeEventType]
    
    init(selectedType: Binding<LifeEventType?>) {
        _selectedType = selectedType
        let predicate = #Predicate<LifeEventType> { $0.parentRid == nil && $0.cache == true }
        _typesTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        GenericTreeSelectorView(
            items: typesTree,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedType,
            title: "Select a Life Event Type",
            noneButtonText: "None"
        )
    }
}

struct ParentLifeEventTypeSelector: View {
    let types: [LifeEventType]
    @Binding var selectedParent: LifeEventType?
    
    var body: some View {
        GenericTreeSelectorView(
            items: types,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedParent,
            title: "Select Parent",
            noneButtonText: "Top Level (No Parent)"
        )
    }
}
