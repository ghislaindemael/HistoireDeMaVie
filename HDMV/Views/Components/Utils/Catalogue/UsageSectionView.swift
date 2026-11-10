//
//  UsageSectionView.swift
//  HDMV
//
//  Created by Ghislain on 10.11.2026.
//

import SwiftUI

struct UsageSectionView<Content: View>: View {
    var title: String
    @Binding var isCached: Bool
    @Binding var isArchived: Bool
    var isSelectable: Binding<Bool>?
    var isFavorite: Binding<Bool>?
    @ViewBuilder var extraContent: Content

    init(
        title: String = "Usage",
        isCached: Binding<Bool>,
        isArchived: Binding<Bool>,
        isSelectable: Binding<Bool>? = nil,
        isFavorite: Binding<Bool>? = nil,
        @ViewBuilder extraContent: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self._isCached = isCached
        self._isArchived = isArchived
        self.isSelectable = isSelectable
        self.isFavorite = isFavorite
        self.extraContent = extraContent()
    }

    var body: some View {
        Section(title) {
            if let isSelectable {
                Toggle("Selectable", isOn: isSelectable)
            }
            if let isFavorite {
                Toggle("Favorite", isOn: isFavorite)
            }
            Toggle("Cached", isOn: $isCached)
            Toggle("Archived", isOn: $isArchived)
            extraContent
        }
    }
}

extension UsageSectionView where Content == EmptyView {
    init(
        title: String = "Usage",
        isCached: Binding<Bool>,
        isArchived: Binding<Bool>,
        isSelectable: Binding<Bool>? = nil,
        isFavorite: Binding<Bool>? = nil
    ) {
        self.init(
            title: title,
            isCached: isCached,
            isArchived: isArchived,
            isSelectable: isSelectable,
            isFavorite: isFavorite,
            extraContent: { EmptyView() }
        )
    }
}
