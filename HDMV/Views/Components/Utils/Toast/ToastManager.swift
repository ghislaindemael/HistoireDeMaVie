import SwiftUI
import Combine

@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var message: String = ""
    @Published var systemImage: String = "info.circle.fill"
    @Published var color: Color = .primary
    
    private var dismissTask: Task<Void, Never>?
    
    func showToast(message: String, systemImage: String = "info.circle.fill", color: Color = .primary, duration: TimeInterval = 3.0) {
        self.message = message
        self.systemImage = systemImage
        self.color = color
        
        withAnimation(.spring()) {
            self.isShowing = true
        }
        
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.spring()) {
                self.isShowing = false
            }
        }
    }
}
