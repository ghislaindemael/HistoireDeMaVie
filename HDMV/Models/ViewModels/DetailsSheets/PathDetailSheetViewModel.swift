//
//  PathDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class PathDetailSheetViewModel: BaseDetailSheetViewModel<Path, PathEditor>{
    @Published var isShowingGpxFileImporter = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let gpxParser = GPXParserService()
    private let storageService = StorageService()


    // MARK: - User Actions

    func importButtonTapped() {
        guard editor.rid != nil else {
            errorMessage = "Please save the path before attaching a GPX file."
            return
        }
        isShowingGpxFileImporter = true
    }

    // In PathDetailViewModel.swift
    
    func handleFileImport(result: Result<URL, Error>) {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            guard let rid = editor.rid else { return }
            
            switch result {
                case .success(let url):
                    let shouldStopAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if shouldStopAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    guard FileManager.default.isReadableFile(atPath: url.path) else {
                        errorMessage = "The selected file is not readable. Please check the file and try again."
                        return
                    }
                    
                    let destURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    do {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destURL)
                    } catch {
                        errorMessage = "Could not copy the file into the app. Please try again. Error: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let gpxData = gpxParser.parse(url: destURL) else {
                        errorMessage = "Failed to parse GPX file."; return
                    }
                    editor.metrics = gpxData.metrics
                    editor.geojson_track = gpxData.geojsonCoordinates
                    
                    do {
                        
                        _ = try await storageService.uploadGPX(fileURL: destURL, for: rid)
                    } catch {
                        errorMessage = "Failed to upload file: \(error.localizedDescription)"
                    }
                    
                case .failure(let error):
                    errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }


}
