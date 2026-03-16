//
//  VaultLinkerSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 16.03.2026.
//

import SwiftUI
import SwiftData
import Supabase

struct VaultLinkerSheet: View {
    let fileURL: URL
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Trip.timeStart, order: .reverse)
    private var allTrips: [Trip]
    
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    @State private var targetDate: Date = .now
    
    private var matchingTrips: [Trip] {
        let calendar = Calendar.current
        return allTrips.filter { trip in
            trip.rid != nil && calendar.isDate(trip.timeStart, inSameDayAs: targetDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "doc.zipper")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(fileURL.lastPathComponent)
                                .font(.headline)
                                .lineLimit(1)
                            Text("Select a trip to attach this file to.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Search Date") {
                    DatePicker(
                        "Showing trips for:",
                        selection: $targetDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                
                Section("Trips on \(targetDate.formatted(date: .abbreviated, time: .omitted))") {
                    if matchingTrips.isEmpty {
                        Text("No synced trips found for this date.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(matchingTrips) { trip in
                            Button {
                                Task { await attachAndUpload(to: trip) }
                            } label: {
                                TripRowView(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Vault File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        VaultImportService.shared.cleanupFile()
                    }
                    .disabled(isUploading)
                }
            }
            .onAppear {
                autoDetectFileDate()
            }
            .overlay {
                if isUploading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Uploading to Vault...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Upload Failed", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Date Detection
    
    private func autoDetectFileDate() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            if let creationDate = attributes[.creationDate] as? Date {
                self.targetDate = creationDate
                print("Auto-detected file date: \(creationDate)")
            } else if let modDate = attributes[.modificationDate] as? Date {
                self.targetDate = modDate
            }
        } catch {
            print("Could not read file attributes: \(error)")
        }
    }
    
    // MARK: - Upload Logic
    
    @MainActor
    private func attachAndUpload(to trip: Trip) async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            guard let client = SupabaseService.shared.client else {
                throw NSError(domain: "HDMV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client is not initialized."])
            }
            
            let fileData = try Data(contentsOf: fileURL)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/yyyy-MM-dd_HH-mm"
            let datePrefix = formatter.string(from: trip.timeStart)
            
            guard let tripId = trip.rid else { return }
            
            let fileExtension = fileURL.pathExtension.isEmpty ? "fit" : fileURL.pathExtension
            let storagePath = "fit_files/\(datePrefix)_trip_\(tripId).\(fileExtension)"
            
            try await client.storage
                .from("vault")
                .upload(
                    storagePath,
                    data: fileData,
                    options: FileOptions(contentType: "application/octet-stream")
                )
            
            print("✅ Successfully uploaded to Supabase Storage: \(storagePath)")
            
            trip.fitFilePath = storagePath
            trip.markAsModified()
            try modelContext.save()
            
            VaultImportService.shared.cleanupFile()
            
        } catch {
            print("🚨 Failed to upload: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
