//
//  LogPageToolbar.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct LogPageToolbar<MenuContent: View>: ViewModifier {
    let refreshAction: () async -> Void
    let syncAction: () async -> Void
    let primaryAddAction: () -> Void
    
    let hasExtraOptions: Bool
    let extraMenuOptions: MenuContent
    
    @ObservedObject private var settings = SettingsStore.shared
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading Menu (Settings/Sync)
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: { Task { await refreshAction() } }) {
                            Label("Refresh from Server", systemImage: "icloud.and.arrow.down")
                        }
                        Button(action: { Task { await syncAction() } }) {
                            Label("Sync local changes", systemImage: "icloud.and.arrow.up")
                        }
                        Button(action: { settings.planningMode.toggle() }) {
                            Label {
                                Text("\(settings.planningMode ? "Exit": "Enter") Planning Mode")
                            } icon: {
                                Image(systemName: settings.planningMode ? "calendar.badge.minus" : "calendar.badge.plus")
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
                
                // MARK: - Trailing Actions
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: primaryAddAction) {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if hasExtraOptions {
                            Menu {
                                extraMenuOptions
                            } label: {
                                Image(systemName: "ellipsis")
                                    .frame(width: 30, height: 40)
                                    .contentShape(Rectangle())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    
    /// For pages that need the "Long Press" menu (Activities, Agenda)
    func logPageToolbar<Content: View>(
        refreshAction: @escaping () async -> Void,
        syncAction: @escaping () async -> Void,
        onAdd: @escaping () -> Void,
        @ViewBuilder menuOptions: @escaping () -> Content
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                primaryAddAction: onAdd,
                hasExtraOptions: true,
                extraMenuOptions: menuOptions()
            )
        )
    }
    
    /// For simple catalogue pages (Paths, People, Interactions)
    func simpleLogToolbar(
        refreshAction: @escaping () async -> Void,
        syncAction: @escaping () async -> Void,
        onAdd: @escaping () -> Void
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                primaryAddAction: onAdd,
                hasExtraOptions: false,
                extraMenuOptions: EmptyView()
            )
        )
    }
}
