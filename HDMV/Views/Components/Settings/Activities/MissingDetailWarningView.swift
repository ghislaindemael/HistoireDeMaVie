import SwiftUI

struct MissingDetailWarningView: View {
    let message: String
    let iconName: String?
    let isRequired: Bool
    
    init(message: String, iconName: String? = nil, isRequired: Bool = true) {
        self.message = message
        self.iconName = iconName
        self.isRequired = isRequired
    }
    
    var body: some View {
        let alertColor: Color = isRequired ? .red : .orange
        
        HStack(spacing: 6) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.subheadline)
            }
            Text(message)
                .font(.body)
                .fontWeight(isRequired ? .bold : .semibold)
            Spacer()
        }
        .padding(8)
        .background(alertColor.opacity(0.1))
        .foregroundStyle(alertColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 8) {
        MissingDetailWarningView(message: "Missing Workout Details", iconName: "exclamationmark.triangle.fill", isRequired: true)
        MissingDetailWarningView(message: "Media not logged.", iconName: nil, isRequired: false)
    }
    .padding()
}
