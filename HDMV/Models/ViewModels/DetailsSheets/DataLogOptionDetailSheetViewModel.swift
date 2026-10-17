//
//  DataLogOptionDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

@MainActor
class DataLogOptionDetailSheetViewModel: BaseDetailSheetViewModel<DataLogOption, DataLogOptionEditor> {
    
    func addChoice(slug: String, label: String, icon: String?) {
        if editor.config == nil {
            editor.config = DataLogOptionConfig()
        }
        if editor.config?.choices == nil {
            editor.config?.choices = []
        }
        let newChoice = DataLogOptionChoice(slug: slug, label: label, icon: icon, archived: false)
        editor.config?.choices?.append(newChoice)
    }
    
    func removeChoice(at index: Int) {
        editor.config?.choices?.remove(at: index)
    }

    // MARK: - Global Scopes (Option Config)
    
    var isForTransaction: Bool {
        get { editor.config?.isForTransaction ?? false }
        set {
            if editor.config == nil { editor.config = DataLogOptionConfig() }
            editor.config?.isForTransaction = newValue
        }
    }
    
    var isForInteraction: Bool {
        get { editor.config?.isForInteraction ?? false }
        set {
            if editor.config == nil { editor.config = DataLogOptionConfig() }
            editor.config?.isForInteraction = newValue
        }
    }
    
    // MARK: - Vehicle Type Mappings
    
    func isForVehicleType(_ type: VehicleType) -> Bool {
        return model.mappings?.first(where: { $0.vehicleTypeSlug == type.rawValue }) != nil
    }
    
    func setForVehicleType(_ type: VehicleType, isOn: Bool) {
        let existingMapping = model.mappings?.first(where: { $0.vehicleTypeSlug == type.rawValue })
        
        if isOn {
            if existingMapping == nil {
                let newMapping = DataLogOptionMapping(optionSlug: model.slug)
                newMapping.vehicleTypeSlug = type.rawValue
                newMapping.option = model
                modelContext.insert(newMapping)
                if model.mappings == nil { model.mappings = [] }
                model.mappings?.append(newMapping)
            }
        } else {
            if let mapping = existingMapping {
                modelContext.delete(mapping)
                model.mappings?.removeAll(where: { $0.id == mapping.id })
            }
        }
    }
    
    override func onDone() {
        super.onDone()
        if model.slug.isNotUnset() && model.slug != "!unset" {
            for mapping in model.mappings ?? [] {
                if mapping.optionSlug != model.slug {
                    mapping.optionSlug = model.slug
                }
            }
            try? modelContext.save()
        }
    }

}
