//
//  VaultLinkerSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 16.03.2026.
//

import SwiftUI
import SwiftData
import Supabase

enum VaultLinkTarget {
    case trip
    case activity
}

struct VaultLinkerSheet: View {
    let fileURL: URL
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Trip.timeStart, order: .reverse)
    private var allTrips: [Trip]
    
    @Query(sort: \ActivityInstance.timeStart, order: .reverse)
    private var allActivities: [ActivityInstance]
    
    @State private var selectedTarget: VaultLinkTarget = .trip
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var targetDate: Date = .now
    
    private var matchingTrips: [Trip] {
        let calendar = Calendar.current
        return allTrips.filter { trip in
            trip.rid != nil && calendar.isDate(trip.timeStart, inSameDayAs: targetDate)
        }
    }
    
    private var matchingActivities: [ActivityInstance] {
        let calendar = Calendar.current
        return allActivities.filter { activity in
            activity.rid != nil && calendar.isDate(activity.timeStart, inSameDayAs: targetDate)
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
                            Text("Select a record to attach this file to.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Search Date") {
                    DatePicker(
                        "Showing records for:",
                        selection: $targetDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                
                Section {
                    Picker("Target", selection: $selectedTarget) {
                        Text("Trips").tag(VaultLinkTarget.trip)
                        Text("Activities").tag(VaultLinkTarget.activity)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                Section("\(selectedTarget == .trip ? "Trips" : "Activities") on \(targetDate.formatted(date: .abbreviated, time: .omitted))") {
                    
                    if selectedTarget == .trip {
                        if matchingTrips.isEmpty {
                            Text("No synced trips found for this date.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(matchingTrips) { trip in
                                Button {
                                    Task { await attachAndUpload(to: trip) }
                                } label: {
                                    TripRowSimple(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        if matchingActivities.isEmpty {
                            Text("No synced activities found for this date.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(matchingActivities) { activity in
                                Button {
                                    Task { await attachAndUpload(toActivity: activity) }
                                } label: {
                                    ActivityRowSimple(activity: activity)
                                }
                                .buttonStyle(.plain)
                            }
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
    
    // MARK: - Upload Logic (Trip)
    
    @MainActor
    private func attachAndUpload(to trip: Trip) async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            guard let client = SupabaseService.shared.client else {
                throw NSError(domain: "HDMV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized."])
            }
            
            let fileData = try Data(contentsOf: fileURL)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/yyyy-MM-dd_HH-mm"
            let datePrefix = formatter.string(from: trip.timeStart)
            
            guard let tripId = trip.rid else { return }
            
            let fileExtension = fileURL.pathExtension.isEmpty ? "fit" : fileURL.pathExtension
            let storagePath = "fit_files/\(datePrefix)_trip_\(tripId).\(fileExtension)"
            
            try await client.storage.from("vault").upload(
                storagePath,
                data: fileData,
                options: FileOptions(contentType: "application/octet-stream")
            )
            
            trip.fitFilePath = storagePath
            trip.markAsModified()
            try modelContext.save()
            VaultImportService.shared.cleanupFile()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Upload Logic (Activity)
    @MainActor
    private func attachAndUpload(toActivity activity: ActivityInstance) async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            guard let client = SupabaseService.shared.client else {
                throw NSError(domain: "HDMV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized."])
            }
            
            let fileData = try Data(contentsOf: fileURL)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/yyyy-MM-dd_HH-mm"
            let datePrefix = formatter.string(from: activity.timeStart)
            
            guard let activityId = activity.rid else { return }
            
            let fileExtension = fileURL.pathExtension.isEmpty ? "fit" : fileURL.pathExtension
            let storagePath = "fit_files/\(datePrefix)_activity_\(activityId).\(fileExtension)"
            
            try await client.storage.from("vault").upload(
                storagePath,
                data: fileData,
                options: FileOptions(contentType: "application/octet-stream")
            )
            
            activity.fitFilePath = storagePath
            activity.markAsModified()
            try modelContext.save()
            VaultImportService.shared.cleanupFile()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Simple Row Helpers
struct TripRowSimple: View {
    let trip: Trip
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.timeStart, style: .time).font(.headline)
                if let details = trip.details {
                    Text(details).font(.caption).lineLimit(1).foregroundColor(.secondary)
                }
            }
            Spacer()
            if trip.fitFilePath != nil { Image(systemName: "checkmark.icloud.fill").foregroundColor(.green) }
        }
    }
}

struct ActivityRowSimple: View {
    let activity: ActivityInstance
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(activity.timeStart, style: .time).font(.headline)
                if let details = activity.details {
                    Text(details).font(.caption).lineLimit(1).foregroundColor(.secondary)
                }
            }
            Spacer()
            if activity.fitFilePath != nil { Image(systemName: "checkmark.icloud.fill").foregroundColor(.green) }
        }
    }
}
