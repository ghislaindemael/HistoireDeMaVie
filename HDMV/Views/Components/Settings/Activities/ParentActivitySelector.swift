//
//  ParentActivitySelector.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//

import SwiftUI

struct ParentActivitySelector: View {
    let activities: [Activity]
    @Binding var selectedParent: Activity?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Button("Top Level (No Parent)") {
                selectedParent = nil
                dismiss()
            }
            
            OutlineGroup(activities, children: \.optionalChildren) { activity in
                
                Button(action: {
                    selectedParent = activity
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon ?? "")
                            .foregroundStyle(.primary)
                        Text(activity.name ?? "Unset")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Select Parent")
    }
}
