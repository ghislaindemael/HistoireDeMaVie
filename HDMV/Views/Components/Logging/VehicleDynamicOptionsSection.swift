import SwiftUI
import SwiftData

struct VehicleDynamicOptionsSection: View {
    @Query private var mappings: [DataLogOptionMapping]
    @Binding var decodedLogDetails: LogDetails?
    
    init(vehicleRid: Int?, decodedLogDetails: Binding<LogDetails?>) {
        self._decodedLogDetails = decodedLogDetails
        let vId = vehicleRid ?? -1
        _mappings = Query(filter: #Predicate<DataLogOptionMapping> { $0.vehicleRid == vId }, sort: \DataLogOptionMapping.priority)
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
