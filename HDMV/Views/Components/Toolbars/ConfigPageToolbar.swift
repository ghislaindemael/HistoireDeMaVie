//
//  StandardConfigPageToolbar.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

/// A reusable ViewModifier that applies a standard toolbar configuration for data management pages.
///
/// This modifier adds a leading menu with "Refresh" and "Re-cache" options,
/// and a trailing "Add" button. It is designed to be generic and can be configured
/// for different data types (e.g., "countries", "cities").
struct ConfigPageToolbar: ViewModifier {
    @EnvironmentObject var settings: SettingsStore
    
    /// An asynchronous closure to be executed when the "Refresh" button is tapped.
    let refreshAction: () async -> Void
    
    /// A closure to be executed when the "Re-cache" button is tapped.
    let cacheAction: () -> Void
    
    /// A binding to a Boolean value that determines whether the sheet for creating a new item is presented.
    @Binding var isShowingAddSheet: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading Menu
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            Task {
                                await refreshAction()
                            }
                        }) {
                            Label(
                                "Refresh \(settings.includeArchived ? "all " : "")",
                                systemImage: "icloud.and.arrow.down"
                            )
                        }
                        
                        Button(action: cacheAction) {
                            Label("Re-cache", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        }
                        
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
                
                // MARK: - Trailing Add Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    /// Applies a standard toolbar for configuration pages with refresh, cache, and add actions.
    /// - Parameters:
    ///   - refreshAction: The asynchronous action to perform on refresh.
    ///   - cacheAction: The action to perform on cache.
    ///   - addAction: The action to perform to add a new item.
    func standardConfigPageToolbar(
        refreshAction: @escaping () async -> Void,
        cacheAction: @escaping () -> Void,
        isShowingAddSheet: Binding<Bool>
    ) -> some View {
        self.modifier(
            ConfigPageToolbar(
                refreshAction: refreshAction,
                cacheAction: cacheAction,
                isShowingAddSheet: isShowingAddSheet
            )
        )
    }
}
