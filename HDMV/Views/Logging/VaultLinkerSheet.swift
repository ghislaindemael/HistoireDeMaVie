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
        
    @State private var selectedTarget: VaultLinkTarget = .trip
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var targetDate: Date = .now
    
    // MARK: - Main Body
    
    var body: some View {
        NavigationStack {
            List {
                headerSection
                searchDateSection
                targetPickerSection
                
                VaultFilteredResultsView(
                    targetDate: targetDate,
                    selectedTarget: selectedTarget,
                    onTripSelected: { trip in
                        Task { await attachAndUpload(to: trip) }
                    },
                    onActivitySelected: { activity in
                        Task { await attachAndUpload(toActivity: activity) }
                    }
                )
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
                uploadOverlay
            }
            .alert("Upload Failed", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private var headerSection: some View {
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
    }
    
    @ViewBuilder
    private var searchDateSection: some View {
        Section("Search Date") {
            DatePicker(
                "Showing records for:",
                selection: $targetDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
    }
    
    @ViewBuilder
    private var targetPickerSection: some View {
        Section {
            Picker("Target", selection: $selectedTarget) {
                Text("Trips").tag(VaultLinkTarget.trip)
                Text("Activities").tag(VaultLinkTarget.activity)
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    private var uploadOverlay: some View {
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
    
    // MARK: - Date Detection
    
    private func autoDetectFileDate() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            if let creationDate = attributes[.creationDate] as? Date {
                self.targetDate = creationDate
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
                options: FileOptions(contentType: "application/octet-stream", upsert: true)
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
                options: FileOptions(contentType: "application/octet-stream", upsert: true)
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

// MARK: - Query Subview

struct VaultFilteredResultsView: View {
    var selectedTarget: VaultLinkTarget
    
    @Query private var trips: [Trip]
    @Query private var activities: [ActivityInstance]
    
    let onTripSelected: (Trip) -> Void
    let onActivitySelected: (ActivityInstance) -> Void
    
    init(targetDate: Date, selectedTarget: VaultLinkTarget, onTripSelected: @escaping (Trip) -> Void, onActivitySelected: @escaping (ActivityInstance) -> Void) {
        self.selectedTarget = selectedTarget
        self.onTripSelected = onTripSelected
        self.onActivitySelected = onActivitySelected
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let tripPredicate = #Predicate<Trip> { $0.timeStart >= startOfDay && $0.timeStart < endOfDay && $0.rid != nil }
        _trips = Query(filter: tripPredicate, sort: \.timeStart, order: .reverse)
        
        let activityPredicate = #Predicate<ActivityInstance> { $0.timeStart >= startOfDay && $0.timeStart < endOfDay && $0.rid != nil }
        _activities = Query(filter: activityPredicate, sort: \.timeStart, order: .reverse)
    }
    
    private var unlinkedTrips: [Trip] { trips.filter { $0.fitFilePath == nil } }
    private var linkedTrips: [Trip] { trips.filter { $0.fitFilePath != nil } }
    
    private var unlinkedActivities: [ActivityInstance] { activities.filter { $0.fitFilePath == nil } }
    private var linkedActivities: [ActivityInstance] { activities.filter { $0.fitFilePath != nil } }
    
    var body: some View {
        if selectedTarget == .trip {
            if trips.isEmpty {
                Section {
                    Text("No synced trips found for this date.")
                        .foregroundColor(.secondary)
                }
            } else {
                if !unlinkedTrips.isEmpty {
                    Section("Needs File") {
                        ForEach(unlinkedTrips) { trip in
                            Button { onTripSelected(trip) } label: { TripRowView(trip: trip) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                if !linkedTrips.isEmpty {
                    Section("Already Vaulted") {
                        ForEach(linkedTrips) { trip in
                            Button { onTripSelected(trip) } label: { TripRowView(trip: trip) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            if activities.isEmpty {
                Section {
                    Text("No synced activities found for this date.")
                        .foregroundColor(.secondary)
                }
            } else {
                if !unlinkedActivities.isEmpty {
                    Section("Needs File") {
                        ForEach(unlinkedActivities) { act in
                            Button { onActivitySelected(act) } label: { ActivityInstanceRowView(instance: act) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                if !linkedActivities.isEmpty {
                    Section("Already Vaulted") {
                        ForEach(linkedActivities) { act in
                            Button { onActivitySelected(act) } label: { ActivityInstanceRowView(instance: act) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
