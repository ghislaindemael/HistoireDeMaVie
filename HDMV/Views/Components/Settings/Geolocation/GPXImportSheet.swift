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
    case newTrip
    case existingTrip
    case newPath
    case existingPath
}

struct GPXImportSheet: View {
    let fileURL: URL
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Trip.timeStart, order: .reverse)
    private var allTrips: [Trip]
    
    @Query(sort: \Path.name)
    private var allPaths: [Path]
    
    @State private var parsedData: ParsedGPXData?
    @State private var isImporting = false
    @State private var errorMessage: String?
    
    @State private var intent: GPXImportIntent = .newTrip
    
    @State private var newPathName: String = "Imported Route"
    @State private var selectedTrip: Trip?
    @State private var selectedPath: Path?
    
    var body: some View {
        NavigationStack {
            List {
                headerSection
                
                if let data = parsedData {
                    metricsSection(data: data)
                    intentPickerSection
                    intentDetailsSection
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else {
                    ProgressView("Analyzing GPX...")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { VaultImportService.shared.cleanupFile() }
                        .disabled(isImporting)
                }
            }
            .safeAreaInset(edge: .bottom) {
                importButton
            }
            .onAppear {
                parseFile()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("GPX Route Found")
                    .font(.title2).bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private func metricsSection(data: ParsedGPXData) -> some View {
        Section("Route Data") {
            metricRow(title: "Distance", value: "\(String(format: "%.2f", data.metrics.distance / 1000)) km")
            metricRow(title: "Elevation Gain", value: "\(String(format: "%.0f", data.metrics.elevationGain)) m")
            metricRow(title: "Recorded", value: data.timeStart.formatted(date: .abbreviated, time: .shortened))
        }
    }
    
    @ViewBuilder
    private var intentPickerSection: some View {
        Section("Action") {
            Picker("Import As", selection: $intent) {
                Text("New Trip").tag(GPXImportIntent.newTrip)
                Text("Update Trip").tag(GPXImportIntent.existingTrip)
                Text("New Path").tag(GPXImportIntent.newPath)
                Text("Update Path").tag(GPXImportIntent.existingPath)
            }
            .pickerStyle(.menu)
        }
    }
    
    @ViewBuilder
    private var intentDetailsSection: some View {
        Section {
            switch intent {
                case .newTrip:
                    Text("This will log a brand new completed Trip based on the timestamps in the GPX file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                case .existingTrip:
                    Picker("Select Trip", selection: $selectedTrip) {
                        Text("Select a Trip...").tag(Trip?.none)
                        ForEach(allTrips.prefix(50)) { trip in
                            Text("\(trip.timeStart.formatted(date: .abbreviated, time: .shortened))").tag(Trip?.some(trip))
                        }
                    }
                    if selectedTrip != nil {
                        Text("Warning: This will overwrite the selected Trip's GPS data and attach this file to it.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                case .newPath:
                    TextField("Path Name", text: $newPathName)
                    
                case .existingPath:
                    Picker("Select Path", selection: $selectedPath) {
                        Text("Select a Path...").tag(Path?.none)
                        ForEach(allPaths) { path in
                            Text(path.name).tag(Path?.some(path))
                        }
                    }
                    if selectedPath != nil {
                        Text("Warning: This will overwrite the selected Path's route map and attach this file to it.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var importButton: some View {
        Button(action: {
            Task { await processImport() }
        }) {
            if isImporting {
                ProgressView().tint(.white)
            } else {
                Text(buttonText)
                    .bold()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isImportDisabled ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom)
        .disabled(isImportDisabled)
    }
    
    // MARK: - Helpers
    
    private var buttonText: String {
        switch intent {
            case .newTrip: return "Log Trip & Vault File"
            case .existingTrip: return "Update Trip & Vault File"
            case .newPath: return "Save Path & Vault File"
            case .existingPath: return "Update Path & Vault File"
        }
    }
    
    private var isImportDisabled: Bool {
        if parsedData == nil || isImporting { return true }
        if intent == .existingTrip && selectedTrip == nil { return true }
        if intent == .existingPath && selectedPath == nil { return true }
        return false
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
            self.newPathName = "Route: " + data.timeStart.formatted(date: .abbreviated, time: .omitted)
            
            let calendar = Calendar.current
            if let matchingTrip = allTrips.first(where: { calendar.isDate($0.timeStart, inSameDayAs: data.timeStart) }) {
                self.selectedTrip = matchingTrip
                self.intent = .existingTrip
            }
            
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
            
            switch intent {
                case .newTrip:
                    let newTrip = Trip(timeStart: data.timeStart, timeEnd: data.timeEnd)
                    newTrip.pathMetrics = data.metrics
                    newTrip.geojsonTrack = data.geojsonCoordinates
                    newTrip.fitFilePath = vaultPath
                    modelContext.insert(newTrip)
                    
                case .existingTrip:
                    guard let trip = selectedTrip else { return }
                    trip.pathMetrics = data.metrics
                    trip.geojsonTrack = data.geojsonCoordinates
                    trip.fitFilePath = vaultPath
                    trip.markAsModified()
                    
                case .newPath:
                    let newPath = Path(name: newPathName, metrics: data.metrics, geojsonTrack: data.geojsonCoordinates)
                    newPath.gpxFilePath = vaultPath
                    modelContext.insert(newPath)
                    
                case .existingPath:
                    guard let path = selectedPath else { return }
                    path.metrics = data.metrics
                    path.geojsonTrack = data.geojsonCoordinates
                    path.gpxFilePath = vaultPath
                    path.markAsModified() // Assuming Path has this sync flag
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
        
        let recordId: String
        let recordType: String
        
        switch intent {
            case .existingTrip:
                recordId = selectedTrip?.rid.map { String($0) } ?? UUID().uuidString.prefix(8).description
                recordType = "trip"
            case .existingPath:
                recordId = selectedPath?.rid.map { String($0) } ?? UUID().uuidString.prefix(8).description
                recordType = "path"
            default:
                recordId = UUID().uuidString.prefix(8).description
                recordType = intent == .newTrip ? "trip" : "path"
        }
        
        let storagePath = "fit_files/\(datePrefix)_\(recordType)_\(recordId).gpx"
        
        try await client.storage.from("vault").upload(
            storagePath,
            data: fileData,
            options: FileOptions(contentType: "application/octet-stream", upsert: true)
        )
        return storagePath
    }
}
