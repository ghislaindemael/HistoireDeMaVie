import SwiftUI
import SwiftData

struct VehicleDynamicOptionsSection: View {
    @Query private var mappings: [DataLogOptionMapping]
    @Binding var decodedActivityDetails: ActivityDetails?
    
    init(vehicleRid: Int?, decodedActivityDetails: Binding<ActivityDetails?>) {
        self._decodedActivityDetails = decodedActivityDetails
        let vId = vehicleRid ?? -1
        _mappings = Query(filter: #Predicate<DataLogOptionMapping> { $0.vehicleRid == vId }, sort: \DataLogOptionMapping.priority)
    }
    
    var body: some View {
        if !mappings.isEmpty {
            DynamicOptionsSection(
                mappings: mappings,
                decodedActivityDetails: $decodedActivityDetails
            )
        }
    }
}
