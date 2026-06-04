//
//  IconCacheService.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import Foundation

actor IconCacheService {
    static let shared = IconCacheService()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Setup cache directory in the user's documents
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = docs.appendingPathComponent("HDMV_Icons", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create icons cache directory: \(error)")
            }
        }
    }
    
    /// Returns the local file URL if the icon is already cached, otherwise returns nil
    func getCachedIconURL(filename: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }
    
    /// Downloads the icon from Supabase storage and caches it locally
    func downloadAndCacheIcon(filename: String) async throws -> URL {
        // If it's already cached by another concurrent request, return it immediately
        if let existing = getCachedIconURL(filename: filename) {
            return existing
        }
        
        // Use Supabase Storage to download the file
        guard let client = SupabaseService.shared.client else {
            throw URLError(.cannotFindHost)
        }
        
        var data = try await client.storage
            .from("icons")
            .download(path: filename)
        
        // Inject #FFFFFF into downloaded SVG so it can be perfectly tinted via .colorMultiply()
        if let svgString = String(data: data, encoding: .utf8) {
            let processedString = svgString
                .replacingOccurrences(of: "fill=\"#000000\"", with: "fill=\"#FFFFFF\"", options: .caseInsensitive)
                .replacingOccurrences(of: "stroke=\"#000000\"", with: "stroke=\"#FFFFFF\"", options: .caseInsensitive)
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"#FFFFFF\"", options: .caseInsensitive)
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"#FFFFFF\"", options: .caseInsensitive)
                .replacingOccurrences(of: "fill=\"currentColor\"", with: "fill=\"#FFFFFF\"", options: .caseInsensitive)
                .replacingOccurrences(of: "stroke=\"currentColor\"", with: "stroke=\"#FFFFFF\"", options: .caseInsensitive)
            
            if let processedData = processedString.data(using: .utf8) {
                data = processedData
            }
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    /// Returns the number of cached icon files
    func getCacheCount() -> Int {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return contents.count
        } catch {
            return 0
        }
    }
    
    /// Returns the list of cached filenames
    func getCachedFiles() -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path)
            return contents.filter { $0.hasSuffix(".svg") }.sorted()
        } catch {
            return []
        }
    }
    
    /// Deletes a specific cached icon
    func deleteCachedIcon(filename: String) {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to delete cached icon \(filename): \(error)")
        }
    }
    
    /// Wipes all downloaded SVG icons
    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear icons cache: \(error)")
        }
    }
}
