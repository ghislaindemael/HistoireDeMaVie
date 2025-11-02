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
    /// A closure for the single-tap action.
    let singleTapAction: () -> Void
    /// A closure for the long-press action.
    let longPressAction: () -> Void
    
    @ObservedObject private var settings = SettingsStore.shared


    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading Menu
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: { Task { await refreshAction() } }) {
                            Label("Refresh from Server", systemImage: "icloud.and.arrow.down")
                        }
                        
                        Button(action: { Task { await syncAction() } }) {
                            Label("Sync local changes", systemImage: "icloud.and.arrow.up")
                        }
                        
                        Button(action: {
                            settings.planningMode.toggle()
                        }) {
                            Label {
                                Text("\(settings.planningMode ? "Exit": "Enter") Planning Mode")
                            } icon: {
                                if settings.planningMode {
                                    Image(systemName: "calendar.badge.minus")
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                }
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
                
                // MARK: - Trailing Add Button
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "plus")
                        .onLongPressGesture {
                            longPressAction()
                        }
                    
                        .onTapGesture {
                            singleTapAction()
                        }
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
        singleTapAction: @escaping () -> Void,
        longPressAction: @escaping () -> Void,
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                singleTapAction: singleTapAction,
                longPressAction: longPressAction
            )
        )
    }
}
