//
//  LifeContextSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI
import SwiftData

struct LifeContextSelectorView: View {
    @Binding var selectedContext: LifeContext?
    @Query var contextTree: [LifeContext]
    
    init(selectedContext: Binding<LifeContext?>) {
        _selectedContext = selectedContext
        let predicate = #Predicate<LifeContext> { $0.parentRid == nil }
        _contextTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        GenericTreeSelectorView(
            items: contextTree,
            childrenKeyPath: \.optionalChildren,
            selection: $selectedContext,
            title: "Select a Context",
            noneButtonText: "None"
        )
    }
}

struct MultiLifeContextSelector: View {
    @Binding var selectedContexts: [Int]
    @Query var contextTree: [LifeContext]
    
    init(selectedContexts: Binding<[Int]>) {
        _selectedContexts = selectedContexts
        let predicate = #Predicate<LifeContext> { $0.parentRid == nil }
        _contextTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        GenericMultiTreeSelectorView(
            items: contextTree,
            childrenKeyPath: \.optionalChildren,
            selections: $selectedContexts,
            title: "Select Contexts"
        )
    }
}

struct ParentLifeContextSelector: View {
    let contexts: [LifeContext]
    @Binding var selectedParent: LifeContext?
    
    var body: some View {
        GenericTreeSelectorView(
            items: contexts,
            childrenKeyPath: \.optionalChildren,
            selection: $selectedParent,
            title: "Select Parent",
            noneButtonText: "Top Level (No Parent)"
        )
    }
}
