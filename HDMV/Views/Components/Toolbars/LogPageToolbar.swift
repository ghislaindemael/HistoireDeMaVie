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
    /// A boolean to determine if the "Save" button should be shown.
    let hasLocalChanges: Bool
    /// An async closure for the "Save" (sync) action.
    let syncAction: () async -> Void
    /// A closure for the single-tap action.
    let singleTapAction: () -> Void
    /// A closure for the long-press action.
    let longPressAction: () -> Void


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
                                Label("Sync local changes", systemImage: "icloud.and.arrow.up")
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
                        longPressAction()
                    })
                    .simultaneousGesture(TapGesture().onEnded {
                        singleTapAction()
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
        hasLocalChanges: Bool,
        syncAction: @escaping () async -> Void,
        singleTapAction: @escaping () -> Void,
        longPressAction: @escaping () -> Void,
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                hasLocalChanges: hasLocalChanges,
                syncAction: syncAction,
                singleTapAction: singleTapAction,
                longPressAction: longPressAction
            )
        )
    }
}
