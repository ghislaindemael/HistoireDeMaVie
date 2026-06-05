//
//  DataActivityOptionDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

@MainActor
class DataActivityOptionDetailSheetViewModel: BaseDetailSheetViewModel<DataActivityOption, DataActivityOptionEditor> {
    
    // Add any specific option-editing logic here
    func addChoice(_ choice: String) {
        if editor.config == nil {
            editor.config = DataActivityOptionConfig()
        }
        if editor.config?.choices == nil {
            editor.config?.choices = []
        }
        editor.config?.choices?.append(choice)
    }
    
    func removeChoice(at index: Int) {
        editor.config?.choices?.remove(at: index)
    }
}
