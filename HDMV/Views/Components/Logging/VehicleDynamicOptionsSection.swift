import SwiftUI
import SwiftData

struct VehicleDynamicOptionsSection: View {
    @Query private var mappings: [DataLogOptionMapping]
    @Binding var decodedLogDetails: LogDetails?
    
    init(vehicleRid: Int?, vehicleTypeSlug: String?, decodedLogDetails: Binding<LogDetails?>) {
        self._decodedLogDetails = decodedLogDetails
        let vId = vehicleRid ?? -1
        let vSlug = vehicleTypeSlug ?? "unset"
        
        // Fetch mappings where either the specific vehicle ID matches OR the generic vehicle type matches
        _mappings = Query(filter: #Predicate<DataLogOptionMapping> { 
            $0.vehicleRid == vId || $0.vehicleTypeSlug == vSlug
        }, sort: \DataLogOptionMapping.priority)
    }
    
    var body: some View {
        if !mappings.isEmpty {
            DynamicOptionsSection(
                mappings: mappings,
                decodedLogDetails: $decodedLogDetails
            )
        }
    }
}
