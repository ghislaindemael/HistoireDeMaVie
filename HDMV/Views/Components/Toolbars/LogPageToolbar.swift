//
//  LogPageToolbar.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

/// A reusable ViewModifier that applies a standard toolbar for the MyActivitiesPage.
struct LogPageToolbar: ViewModifier {
    /// An async closure for the "Refresh" action.
    let refreshAction: () async -> Void
    /// An async closure for the "Save" (sync) action.
    let syncAction: () async -> Void
    /// A closure for the single-tap "Add Now" action.
    let addNowAction: () -> Void
    /// A closure for the long-press "Add at Noon" action.
    let addAtNoonAction: () -> Void
    /// A boolean to determine if the "Save" button should be shown.
    let hasLocalChanges: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading Menu
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: { Task { await refreshAction() } }) {
                            Label("Refresh from Server", systemImage: "icloud.and.arrow.down")
                        }
                        
                        if hasLocalChanges {
                            Button(action: { Task { await syncAction() } }) {
                                Label("Save Local Changes", systemImage: "icloud.and.arrow.up")
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
                
                // MARK: - Trailing Add Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                    .simultaneousGesture(LongPressGesture().onEnded { _ in
                        addAtNoonAction()
                    })
                    .simultaneousGesture(TapGesture().onEnded {
                        addNowAction()
                    })
                }
            }
    }
}

// MARK: - View Extension
extension View {
    /// Applies a standard toolbar for the My Activities page.
    func logPageToolbar(
        refreshAction: @escaping () async -> Void,
        syncAction: @escaping () async -> Void,
        addNowAction: @escaping () -> Void,
        addAtNoonAction: @escaping () -> Void,
        hasLocalChanges: Bool
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                addNowAction: addNowAction,
                addAtNoonAction: addAtNoonAction,
                hasLocalChanges: hasLocalChanges
            )
        )
    }
}
