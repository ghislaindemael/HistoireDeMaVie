//
//  ParentActivitySelector.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//

import SwiftUI

struct ParentActivitySelector: View {
    let activities: [Activity]
    @Binding var selectedParentId: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Button("Top Level") {
                selectedParentId = nil
                dismiss()
            }
            
            OutlineGroup(activities, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedParentId = activity.id
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon)
                            .foregroundStyle(.primary)
                        Text(activity.name)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Select Parent")
    }
}
