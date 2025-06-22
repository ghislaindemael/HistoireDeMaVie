//
//  SyncStatus.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//

import Foundation

enum SyncStatus: String, Codable, Sendable {
    case synced     // The object is saved to Supabase and is up-to-date.
    case syncing    // The object is attempting an upload to Supabase
    case local      // The object exists locally but has not been saved yet.
    case failed     // The last attempt to save the object to Supabase failed.
    case undef
}
