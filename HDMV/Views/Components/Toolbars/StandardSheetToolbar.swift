//
//  StandardNewModelSheetToolbar.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//


import SwiftUI

struct StandardSheetToolbar: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    var isDoneDisabled: Bool = false
    
    /// Called when the Done button is tapped.
    let onDone: () async -> Void
        
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task { await onDone() }
                        dismiss()
                    }
                    .disabled(isDoneDisabled)
                }
            }
    }
}

extension View {
    /// Adds a standard Cancel/Done toolbar for model creation sheets.
    func standardSheetToolbar(
        isDoneDisabled: Bool = false,
        onDone: @escaping () async -> Void
    ) -> some View {
        self.modifier(
            StandardSheetToolbar(
                isDoneDisabled: isDoneDisabled,
                onDone: onDone
            )
        )
    }
}
