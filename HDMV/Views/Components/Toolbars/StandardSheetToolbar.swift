//
//  StandardNewModelSheetToolbar.swift
//  HDMV
//
//  Created by Ghislain Demael on 30.07.2025.
//


import SwiftUI

struct StandardSheetToolbar: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    /// Called when the Done button is tapped.
    let onDone: () async -> Void
    
    /// Whether the Done button should be enabled.
    let isFormValid: Bool
    
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
                    .disabled(!isFormValid)
                }
            }
    }
}

extension View {
    /// Adds a standard Cancel/Done toolbar for model creation sheets.
    func standardSheetToolbar(
        isFormValid: Bool = true,
        onDone: @escaping () async -> Void
    ) -> some View {
        self.modifier(
            StandardSheetToolbar(
                onDone: onDone,
                isFormValid: isFormValid
            )
        )
    }
}
