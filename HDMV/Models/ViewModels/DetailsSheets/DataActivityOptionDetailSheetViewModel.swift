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
    
    func addChoice(slug: String, label: String, icon: String?) {
        if editor.config == nil {
            editor.config = DataActivityOptionConfig()
        }
        if editor.config?.choices == nil {
            editor.config?.choices = []
        }
        let newChoice = DataActivityOptionChoice(slug: slug, label: label, icon: icon, archived: false)
        editor.config?.choices?.append(newChoice)
    }
    
    func removeChoice(at index: Int) {
        editor.config?.choices?.remove(at: index)
    }
}
