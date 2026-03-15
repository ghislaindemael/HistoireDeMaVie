import SwiftUI

struct LogPageToolbar<LeadingContent: View, TrailingContent: View>: ViewModifier {
    let refreshAction: () async -> Void
    let syncAction: () async -> Void
    let primaryAddAction: () -> Void
    
    let hasLeadingOptions: Bool
    let leadingMenuOptions: LeadingContent
    
    let hasTrailingOptions: Bool
    let trailingMenuOptions: TrailingContent
    
    @ObservedObject private var settings = SettingsStore.shared
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // MARK: - Leading Menu (Settings/Sync + Extras)
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
                        
                        if hasLeadingOptions {
                            Divider()
                            leadingMenuOptions
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
                        
                        if hasTrailingOptions {
                            Menu {
                                trailingMenuOptions
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
    
    /// For pages that need extra menus. You can provide leading options, trailing options, or both!
    func logPageToolbar<LeadingContent: View, TrailingContent: View>(
        refreshAction: @escaping () async -> Void,
        syncAction: @escaping () async -> Void,
        onAdd: @escaping () -> Void,
        @ViewBuilder leadingOptions: @escaping () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailingOptions: @escaping () -> TrailingContent = { EmptyView() }
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                primaryAddAction: onAdd,
                hasLeadingOptions: LeadingContent.self != EmptyView.self,
                leadingMenuOptions: leadingOptions(),
                hasTrailingOptions: TrailingContent.self != EmptyView.self,
                trailingMenuOptions: trailingOptions()
            )
        )
    }
    
    /// For simple catalogue pages (Paths, People, Interactions) that don't need any extra menus
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
                hasLeadingOptions: false,
                leadingMenuOptions: EmptyView(),
                hasTrailingOptions: false,
                trailingMenuOptions: EmptyView()
            )
        )
    }
}
