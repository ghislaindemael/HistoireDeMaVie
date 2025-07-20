//
//  SyncStatusIndicator2 2.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//


import SwiftUI

struct SyncStatusIndicator: View {
    let status: SyncStatus
    
    /// Creates a sync status indicator that can also be a button.
    /// - Parameters:
    ///   - status: The SyncStatus to display.
    init(status: SyncStatus) {
        self.status = status
    }
    
    var body: some View {
        switch status {
            case .synced:
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundStyle(.green)
                
            case .syncing:
                ProgressView()
                    .foregroundStyle(.yellow)
                
            case .local:
                Image(systemName: "xmark.icloud.fill")
                    .foregroundStyle(.orange)
            
            case .failed:
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundStyle(.red)
            case .toDelete:
                Image(systemName: "xmark.icloud.fill")
                    .foregroundStyle(.red)
            case .undef:
                Image(systemName: "xmark.icloud.fill")
                    .foregroundStyle(.primary)
                    
        }
    }
}
