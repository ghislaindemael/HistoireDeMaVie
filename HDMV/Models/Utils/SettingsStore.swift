//
//  SettingsStore.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//
import SwiftUI

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @AppStorage("includeArchived") var includeArchived: Bool = false
    @AppStorage("planningMode") var planningMode: Bool = false
}
