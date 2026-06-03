//
//  TransitServices.swift
//  HDMV
//

import Foundation

final class TransitLinesService: SupabaseDataService<TransitLineDTO, TransitLinePayload> {
    init() {
        super.init(tableName: "data_transit_lines")
    }
}

final class TransitStationsService: SupabaseDataService<TransitStationDTO, TransitStationPayload> {
    init() {
        super.init(tableName: "data_transit_stations")
    }
}

final class TransitStopsService: SupabaseDataService<TransitStopDTO, TransitStopPayload> {
    init() {
        super.init(tableName: "data_transit_stops")
    }
}
