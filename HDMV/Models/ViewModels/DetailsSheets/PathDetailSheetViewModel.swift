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
class PathDetailSheetViewModel: ObservableObject {
    @Published var editor: PathEditor
    @Published var isShowingGpxFileImporter = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private var path: Path
    private let modelContext: ModelContext
    
    // Services for handling complex logic
    private let gpxParser = GPXParserService()
    private let storageService = StorageService()

    init(path: Path, modelContext: ModelContext) {
        self.path = path
        self.editor = PathEditor(from: path)
        self.modelContext = modelContext
    }

    // MARK: - User Actions

    func importButtonTapped() {
        guard path.id > 0 else {
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
                        _ = try await storageService.uploadGPX(fileURL: destURL, for: path.id)
                    } catch {
                        errorMessage = "Failed to upload file: \(error.localizedDescription)"
                    }
                    
                case .failure(let error):
                    errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
    
    func addPathSegment(path: Path) {
        if editor.path_ids == nil {
            editor.path_ids = []
        }
        if !(editor.path_ids?.contains(path.id) ?? false) {
            editor.path_ids?.append(path.id)
        }
    }

    func onDone() {
        editor.apply(to: path)
        path.syncStatus = .local
        
        do {
            try modelContext.save()
            print("✅ Path \(path.id) saved to context.")
        } catch {
            print("❌ Failed to save path to context: \(error)")
            errorMessage = "Failed to save changes."
        }
    }
}
