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

    // MARK: - Global Mappings Management
    
    private func getGlobalMapping(condition: (DataLogOptionMapping) -> Bool) -> DataLogOptionMapping? {
        return model.mappings?.first(where: condition)
    }
    
    private func setGlobalMapping(isOn: Bool, keyPath: ReferenceWritableKeyPath<DataLogOptionMapping, Bool>) {
        let existingMapping = model.mappings?.first(where: { $0[keyPath: keyPath] == true })
        
        if isOn {
            if existingMapping == nil {
                let newMapping = DataLogOptionMapping(optionSlug: model.slug)
                newMapping[keyPath: keyPath] = true
                newMapping.option = model
                modelContext.insert(newMapping)
                if model.mappings == nil {
                    model.mappings = []
                }
                model.mappings?.append(newMapping)
            }
        } else {
            if let mapping = existingMapping {
                modelContext.delete(mapping)
                model.mappings?.removeAll(where: { $0.id == mapping.id })
            }
        }
    }
    
    var isForTransaction: Bool {
        get { getGlobalMapping { $0.isForTransaction } != nil }
        set { setGlobalMapping(isOn: newValue, keyPath: \DataLogOptionMapping.isForTransaction) }
    }
    
    var isForInteraction: Bool {
        get { getGlobalMapping { $0.isForInteraction } != nil }
        set { setGlobalMapping(isOn: newValue, keyPath: \DataLogOptionMapping.isForInteraction) }
    }
    
    var isForLifeEvent: Bool {
        get { getGlobalMapping { $0.isForLifeEvent } != nil }
        set { setGlobalMapping(isOn: newValue, keyPath: \DataLogOptionMapping.isForLifeEvent) }
    }
    
    // MARK: - Vehicle Type Mappings
    
    func isForVehicleType(_ type: VehicleType) -> Bool {
        return getGlobalMapping { $0.vehicleTypeSlug == type.rawValue } != nil
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

}
