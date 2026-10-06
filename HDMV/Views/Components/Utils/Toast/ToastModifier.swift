import SwiftUI

struct ToastModifier: ViewModifier {
    @StateObject private var manager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if manager.isShowing {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: manager.systemImage)
                            .foregroundStyle(manager.color)
                        Text(manager.message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground).opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
    }
}

extension View {
    func withGlobalToasts() -> some View {
        self.modifier(ToastModifier())
    }
}
