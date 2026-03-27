//
//  VaultImportService.swift
//  HDMV
//
//  Created by Ghislain Demael on 16.03.2026.
//

import Foundation
import SwiftUI

@MainActor
class VaultImportService: ObservableObject {
    
    static let shared = VaultImportService()
    
    @Published var incomingFileURL: URL?
    @Published var isShowingVaultLinker: Bool = false
    @Published var isShowingGPXImporter: Bool = false
    
    private init() {}
    
    /// Handles the incoming file URL from the iOS Share Sheet
    func handleIncomingURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("VaultImportService: Permission denied to access external file.")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let tempDir = FileManager.default.temporaryDirectory
        let safeLocalURL = tempDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: safeLocalURL.path) {
                try FileManager.default.removeItem(at: safeLocalURL)
            }
            
            try FileManager.default.copyItem(at: url, to: safeLocalURL)
            
            self.incomingFileURL = safeLocalURL
            
            let fileExtension = safeLocalURL.pathExtension.lowercased()
            
            if fileExtension == "fit" {
                self.isShowingVaultLinker = true
                print("VaultImportService: Successfully routed .fit file to Vault Linker.")
            } else if fileExtension == "gpx" {
                self.isShowingGPXImporter = true
                print("VaultImportService: Successfully routed .gpx file to GPX Importer.")
            } else {
                print("VaultImportService: Unsupported file extension -> \(fileExtension)")
            }
            
        } catch {
            print("VaultImportService: Failed to copy incoming file: \(error.localizedDescription)")
        }
    }
    
    /// Call this when you're done uploading to clean up local storage
    func cleanupFile() {
        if let url = incomingFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        self.isShowingVaultLinker = false
        self.isShowingGPXImporter = false
        
        self.incomingFileURL = nil
    }
}
