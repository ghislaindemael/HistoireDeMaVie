//
//  TripDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.10.2025.
//


import SwiftUI
import SwiftData

@MainActor
class TripDetailSheetViewModel: BaseDetailSheetViewModel<Trip, TripEditor> {
    
    @Published var isShowingPathSelector = false
    @Published var isShowingMetricsEditSheet = false

    func selectPath(path: Path) {
        editor.path = path
    }
    
}
