//
//  SettingsStore.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.07.2025.
//
import SwiftUI

enum AppMode: String {
    case live
    case backfill
}

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @AppStorage("includeArchived") var includeArchived: Bool = false
    @AppStorage("appMode") var appMode: AppMode = .live
}
