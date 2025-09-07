//
//  ActivityInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ActivityInstance : SyncableModel, CustomStringConvertible {
    @Attribute(.unique) var id: Int
    var time_start: Date
    var time_end: Date?
    var activity_id: Int?
    var details: String?
    var percentage: Int?
    var activity_details: Data?
    var syncStatus: SyncStatus = SyncStatus.undef


    init(
        id: Int,
        time_start: Date,
        time_end: Date? = nil,
        activity_id: Int? = nil,
        details: String? = nil,
        percentage: Int? = nil,
        activity_details: ActivityDetails? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.time_start = time_start
        self.time_end = time_end
        self.activity_id = activity_id
        self.details = details
        self.percentage = percentage
        self.syncStatus = syncStatus
        self.decodedActivityDetails = activity_details
    }
    
    convenience init(
        fromDto dto: ActivityInstanceDTO
    ){
        self.init(
            id: dto.id,
            time_start: dto.time_start,
            time_end: dto.time_end,
            activity_id: dto.activity_id,
            details: dto.details,
            percentage: dto.percentage,
            syncStatus: .synced
        )
        self.decodedActivityDetails = dto.activity_details
    }
    
    var decodedActivityDetails: ActivityDetails? {
        get {
            guard let data = activity_details else { return nil }
            return try? JSONDecoder().decode(ActivityDetails.self, from: data)
        }
        set {
            activity_details = try? JSONEncoder().encode(newValue)
        }
    }
    
    func update(fromDto dto: ActivityInstanceDTO) {
        self.id = dto.id
        self.time_start = dto.time_start
        self.time_end = dto.time_end
        self.activity_id = dto.activity_id
        self.details = dto.details
        self.percentage = dto.percentage
        self.decodedActivityDetails = dto.activity_details
        self.syncStatus = .synced
    }
    
    var description: String {
        """
        ActivityInstance(
            id: \(id),
            time_start: \(time_start),
            time_end: \(String(describing: time_end)),
            activity_id: \(String(describing: activity_id)),
            details: \(String(describing: details)),
            percentage: \(percentage ?? 100)% 
            syncStatus: \(syncStatus),
            activityDetails: \(activity_details?.debugDescription ?? "nil")        
        )
        """
    }
    
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Start: \(time_start.formatted(date: .abbreviated, time: .shortened))")

                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
        
            if let time_end {
                Text("End: \(time_end.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            if let activity_id {
                Text("Activity ID: \(activity_id)")
            } else {
                Text("Activity: Unset")
                    .bold()
                    .foregroundStyle(.orange)
                
            }
            
            Text("Details: \(details ?? "N/A")")
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    /// Creates a data transfer object (payload) from the model instance.
    func toPayload() -> ActivityInstancePayload {
        return ActivityInstancePayload(
            time_start: self.time_start,
            time_end: self.time_end,
            activity_id: self.activity_id,
            details: self.details,
            percentage: self.percentage,
            activity_details: self.decodedActivityDetails
        )
    }
    
    
}

struct ActivityInstanceDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
    let percentage: Int?
    let activity_details: ActivityDetails?

}


struct ActivityInstancePayload: Codable {
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let details: String?
    let percentage: Int?
    let activity_details: ActivityDetails?
    
    private enum CodingKeys: String, CodingKey {
        case time_start, time_end, activity_id, details, percentage, activity_details
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time_start, forKey: .time_start)
        try container.encode(time_end, forKey: .time_end)
        try container.encode(activity_id, forKey: .activity_id)
        try container.encode(details, forKey: .details)
        try container.encode(percentage, forKey: .percentage)
        try container.encode(activity_details, forKey: .activity_details)
    }
    
}
