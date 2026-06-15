import SwiftUI

struct LogPageToolbar<LeadingContent: View, TrailingContent: View>: ViewModifier {
    let refreshAction: () async -> Void
    let syncAction: () async -> Void
    let primaryAddAction: () -> Void
    
    var fetchArchivedAction: (() async -> Void)? = nil
    var purgeArchivedAction: (() async -> Void)? = nil
    
    let hasLeadingOptions: Bool
    let leadingMenuOptions: LeadingContent
    
    let hasTrailingOptions: Bool
    let trailingMenuOptions: TrailingContent
    let showTrailingOptions: Bool
    
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
                        
                        if fetchArchivedAction != nil || purgeArchivedAction != nil {
                            Divider()
                        }
                        
                        if let fetchArchived = fetchArchivedAction {
                            Button(action: { Task { await fetchArchived() } }) {
                                Label("Fetch Archived Items", systemImage: "archivebox.circle")
                            }
                        }
                        
                        if let purgeArchived = purgeArchivedAction {
                            Button(role: .destructive, action: { Task { await purgeArchived() } }) {
                                Label("Remove Archived from Cache", systemImage: "trash")
                            }
                        }
                        
                        if fetchArchivedAction == nil && purgeArchivedAction == nil {
                            Button(action: { settings.appMode = (settings.appMode == .live) ? .backfill : .live }) {
                                Label {
                                    Text(settings.appMode == .backfill ? "Exit Backfill Mode" : "Enter Backfill Mode")
                                } icon: {
                                    Image(systemName: settings.appMode == .backfill ? "calendar.badge.minus" : "calendar.badge.plus")
                                }
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
                        .disabled(!showTrailingOptions)
                        
                        if hasTrailingOptions {
                            Menu {
                                trailingMenuOptions
                            } label: {
                                Image(systemName: "ellipsis")
                                    .frame(width: 30, height: 40)
                                    .contentShape(Rectangle())
                                    .foregroundStyle(.secondary)
                            }
                            .disabled(!showTrailingOptions)
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
        fetchArchivedAction: (() async -> Void)? = nil,
        purgeArchivedAction: (() async -> Void)? = nil,
        showTrailingOptions: Bool = true,
        @ViewBuilder leadingOptions: @escaping () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailingOptions: @escaping () -> TrailingContent = { EmptyView() }
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                primaryAddAction: onAdd,
                fetchArchivedAction: fetchArchivedAction,
                purgeArchivedAction: purgeArchivedAction,
                hasLeadingOptions: LeadingContent.self != EmptyView.self,
                leadingMenuOptions: leadingOptions(),
                hasTrailingOptions: TrailingContent.self != EmptyView.self,
                trailingMenuOptions: trailingOptions(),
                showTrailingOptions: showTrailingOptions
            )
        )
    }
    
    /// For simple catalogue pages (Paths, People, Interactions) that don't need any extra menus
    func simpleLogToolbar(
        refreshAction: @escaping () async -> Void,
        syncAction: @escaping () async -> Void,
        onAdd: @escaping () -> Void,
        fetchArchivedAction: (() async -> Void)? = nil,
        purgeArchivedAction: (() async -> Void)? = nil,
        showTrailingOptions: Bool = true
    ) -> some View {
        self.modifier(
            LogPageToolbar(
                refreshAction: refreshAction,
                syncAction: syncAction,
                primaryAddAction: onAdd,
                fetchArchivedAction: fetchArchivedAction,
                purgeArchivedAction: purgeArchivedAction,
                hasLeadingOptions: false,
                leadingMenuOptions: EmptyView(),
                hasTrailingOptions: false,
                trailingMenuOptions: EmptyView(),
                showTrailingOptions: showTrailingOptions
            )
        )
    }
}
