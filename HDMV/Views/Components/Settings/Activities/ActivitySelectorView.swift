//
//  ActivitySelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 03.09.2025.
//

import SwiftUI

struct ActivitySelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let activityTree: [Activity]
    @Binding var selectedActivityId: Int?
    
    var body: some View {
        List {
            Button("None") {
                selectedActivityId = nil
                dismiss()
            }
            
            OutlineGroup(activityTree, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedActivityId = activity.id
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon)
                        Text(activity.name)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select an Activity")
    }
}
