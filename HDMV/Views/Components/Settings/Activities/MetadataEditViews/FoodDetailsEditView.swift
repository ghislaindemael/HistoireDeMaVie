import SwiftUI

struct FoodDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    
    private var foodDetailsBinding: Binding<FoodDetails> {
        Binding<FoodDetails>(
            get: {
                return metadata?.food ?? FoodDetails()
            },
            set: { newFoodDetails in
                if metadata == nil {
                    metadata = ActivityDetails()
                }
                metadata?.food = newFoodDetails
            }
        )
    }
    
    var body: some View {
        TextField("General Notes", text: Binding(
            get: { foodDetailsBinding.wrappedValue.generalNotes ?? "" },
            set: { foodDetailsBinding.wrappedValue.generalNotes = $0.isEmpty ? nil : $0 }
        ), axis: .vertical)
        .lineLimit(1...3)
        
        // TODO: Implement Complex ComposedFood builder UI
        Text("Detailed food picking UI coming soon...")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
