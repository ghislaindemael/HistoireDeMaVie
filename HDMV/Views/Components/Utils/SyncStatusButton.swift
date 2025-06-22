import SwiftUI

struct SyncStatusButton: View {
    let status: SyncStatus
    let action: (() -> Void)?
    
    /// Creates a sync status indicator that can also be a button.
    /// - Parameters:
    ///   - status: The SyncStatus to display.
    ///   - action: An optional closure to run when the button is tapped (for local or failed states).
    init(status: SyncStatus, action: (() -> Void)? = nil) {
        self.status = status
        self.action = action
    }
    
    var body: some View {
        switch status {
            case .synced:
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                
            case .syncing:
                ProgressView()
                    .tint(.accentColor)
                
            case .local, .failed:
                Button(action: {
                    action?()
                }) {
                    if status == .local {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .foregroundColor(.accentColor)
                    } else {
                        Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                            .foregroundColor(.red)
                    }
                }
                .disabled(action == nil)
            case .undef:
                Image(systemName: "questionmark.circle.fill")
        }
    }
}
