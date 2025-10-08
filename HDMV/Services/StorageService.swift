//
//  StorageService.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//

import Supabase
import Foundation

class StorageService {
    
    private let supabaseClient = SupabaseService.shared.client
    private let bucketName = "path_gpx_files"

    init() {
        
    }

    /// Uploads a GPX file and returns the remote path.
    func uploadGPX(fileURL: URL, for pathId: Int) async throws -> String {
        guard let client = supabaseClient else {
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Supabase client"])
        }
        
        let remotePath = "path_\(pathId).gpx"
        let fileData = try Data(contentsOf: fileURL)
        
        try await client.storage
            .from(bucketName)
            .upload(remotePath, data: fileData)
        
        return remotePath
    }
}
