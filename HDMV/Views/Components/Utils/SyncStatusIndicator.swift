//
//  SyncStatusIndicator2 2.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//


import SwiftUI

struct SyncStatusIndicator: View {
    let status: SyncStatus
    
    init(status: SyncStatus) {
        self.status = status
    }
    
    var body: some View {
        switch status {
            case .synced:
                IconView(iconString: "checkmark.icloud.fill", tint: .green)
                
            case .syncing:
                IconView(iconString: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill", tint: .blue)
                
            case .local:
                IconView(iconString: "xmark.icloud.fill", tint: .orange)
                
            case .failed:
                IconView(iconString: "exclamationmark.icloud.fill", tint: .red)
                
            case .toDelete:
                IconView(iconString: "xmark.icloud.fill", tint: .red)
                
            case .undef:
                IconView(iconString: "xmark.icloud.fill", tint: .gray)
        }
    }
}
