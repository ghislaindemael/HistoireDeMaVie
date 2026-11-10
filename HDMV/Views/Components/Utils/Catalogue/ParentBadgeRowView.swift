//
//  ParentBadgeRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.11.2026.
//

import SwiftUI

struct ParentBadgeRowView: View {
    let parentInstance: ActivityInstance?
    let parentTrip: Trip?
    var parentInteraction: Interaction? = nil
    
    init(parentInstance: ActivityInstance?, parentTrip: Trip?, parentInteraction: Interaction? = nil) {
        self.parentInstance = parentInstance
        self.parentTrip = parentTrip
        self.parentInteraction = parentInteraction
    }
    
    init(item: any LinkedParent) {
        self.parentInstance = item.parentInstance
        self.parentTrip = item.parentTrip
        self.parentInteraction = (item as? Quote)?.parentInteraction
    }
    
    var body: some View {
        if let parentInteraction {
            badge(
                title: parentInteraction.persons.formattedNames(),
                systemImage: parentInteraction.persons.count > 1 ? "person.2.fill" : "person.fill"
            )
        } else if let parent = parentInstance {
            badge(
                title: parent.activity?.name ?? "Activity",
                systemImage: parent.activity?.icon ?? "flowchart.fill"
            )
        } else if let parentTrip = parentTrip {
            badge(
                title: parentTrip.vehicle?.name ?? parentTrip.name,
                systemImage: parentTrip.vehicle?.type.icon ?? "car.fill"
            )
        }
    }
    
    @ViewBuilder
    private func badge(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.secondaryBackground)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
