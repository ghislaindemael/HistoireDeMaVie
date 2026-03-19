//
//  GPXImportSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.03.2026.
//

import SwiftUI
import SwiftData
import Supabase

enum GPXImportIntent {
    case trip
    case newPath
}

struct GPXImportSheet: View {
    let fileURL: URL
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var parsedData: ParsedGPXData?
    @State private var isImporting = false
    @State private var errorMessage: String?
    
    @State private var intent: GPXImportIntent = .trip
    @State private var pathName: String = "Imported Route"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                Text("GPX Route Found")
                    .font(.title2).bold()
                
                if let data = parsedData {
                    VStack(spacing: 12) {
                        metricRow(title: "Distance", value: "\(String(format: "%.2f", data.metrics.distance / 1000)) km")
                        metricRow(title: "Elevation Gain", value: "\(String(format: "%.0f", data.metrics.elevationGain)) m")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    
                    Picker("Import As", selection: $intent) {
                        Text("Past Trip (Log)").tag(GPXImportIntent.trip)
                        Text("Route Template (Path)").tag(GPXImportIntent.newPath)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)
                    
                    if intent == .newPath {
                        TextField("Path Name", text: $pathName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 32)
                    } else {
                        Text("This will log a completed Trip based on the timestamps in the GPX file.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                } else if errorMessage != nil {
                    Text(errorMessage!)
                        .foregroundStyle(.red)
                        .padding()
                } else {
                    ProgressView("Analyzing GPX...")
                }
                
                Spacer()
                
                Button(action: {
                    Task { await processImport() }
                }) {
                    if isImporting {
                        ProgressView().tint(.white)
                    } else {
                        Text(intent == .trip ? "Log Trip & Vault File" : "Save Path & Vault File")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(parsedData == nil || isImporting ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .disabled(parsedData == nil || isImporting)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { VaultImportService.shared.cleanupFile() }
                        .disabled(isImporting)
                }
            }
            .onAppear { parseFile() }
        }
    }
    
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
    
    private func parseFile() {
        if let data = GPXParserService().parse(url: fileURL) {
            self.parsedData = data
            self.pathName = "Route: " + data.timeStart.formatted(date: .abbreviated, time: .omitted)
        } else {
            self.errorMessage = "Could not parse this GPX file."
        }
    }
    
    // MARK: - Import Routing logic
    
    @MainActor
    private func processImport() async {
        guard let data = parsedData else { return }
        isImporting = true
        defer { isImporting = false }
        
        do {
            let vaultPath = try await uploadToVault(startDate: data.timeStart)
            
            if intent == .trip {
                let newTrip = Trip(
                    timeStart: data.timeStart,
                    timeEnd: data.timeEnd
                )
                newTrip.pathMetrics = data.metrics
                newTrip.geojsonTrack = data.geojsonCoordinates
                newTrip.fitFilePath = vaultPath
                modelContext.insert(newTrip)
                
            } else if intent == .newPath {
                let newPath = Path(
                    name: pathName,
                    metrics: data.metrics,
                    geojsonTrack: data.geojsonCoordinates
                )
                newPath.gpxFilePath = vaultPath
                modelContext.insert(newPath)
            }
            
            try modelContext.save()
            VaultImportService.shared.cleanupFile()
            
        } catch {
            self.errorMessage = "Failed to upload: \(error.localizedDescription)"
        }
    }
    
    private func uploadToVault(startDate: Date) async throws -> String? {
        guard let client = SupabaseService.shared.client else { return nil }
        let fileData = try Data(contentsOf: fileURL)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/yyyy-MM-dd_HH-mm"
        let datePrefix = formatter.string(from: startDate)
        
        let fallbackId = UUID().uuidString.prefix(8)
        let storagePath = "fit_files/\(datePrefix)_gpx_\(fallbackId).gpx"
        
        try await client.storage.from("vault").upload(
            storagePath,
            data: fileData,
            options: FileOptions(contentType: "application/octet-stream")
        )
        return storagePath
    }
}
