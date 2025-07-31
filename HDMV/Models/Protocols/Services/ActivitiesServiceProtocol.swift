//
//  ActivitiesServiceProtocol.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation

/// Defines the contract for a service that manages fetching and modifying `Activity` data.
/// This protocol allows for interchangeable implementations, such as a live network service
/// or a mock service for testing.
protocol ActivitiesServiceProtocol {
    
    /// Fetches a list of activities from the data source.
    /// - Returns: An array of `ActivityDTO` objects.
    /// - Throws: An error if the fetch operation fails.
    func fetchActivities() async throws -> [ActivityDTO]
    
    /// Creates a new activity.
    /// - Parameter payload: A `NewActivityPayload` containing the data for the new activity.
    /// - Returns: The created `ActivityDTO` as returned by the server.
    /// - Throws: An error if the creation operation fails.
    func createActivity(payload: NewActivityPayload) async throws -> ActivityDTO
    
    /// Updates the cache status of a specific activity.
    /// - Parameter activity: The activity to update.
    /// - Throws: An error if the update operation fails.
    func updateCacheStatus(for activity: Activity) async throws
    
    /// Archives a specific activity, marking it as inactive.
    /// - Parameter activity: The activity to archive.
    /// - Throws: An error if the archiving operation fails.
    func archiveActivity(for activity: Activity) async throws
    
    /// Un-archives a specific activity, making it active again.
    /// - Parameter activity: The activity to un-archive.
    /// - Throws: An error if the un-archiving operation fails.
    func unarchiveActivity(for activity: Activity) async throws
}
