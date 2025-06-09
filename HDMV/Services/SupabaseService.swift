//
//  SupabaseService.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.06.2025.
//

import Foundation
import Supabase
import Combine // Can be removed if not used elsewhere, but safe to keep
import KeychainAccess

final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let keychain = Keychain(service: "com.hdmv.supabase")
    
    let client: SupabaseClient?
    
    @Published var session: Session?
    @Published var isAuthenticated = false
    
    private var authTask: Task<Void, Never>?
    
    private init() {
        if let supabaseURL = AppConfig.supabaseURL,
           let supabaseKey = AppConfig.supabaseAnonKey {
            self.client = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: supabaseKey
            )
            print("✅ Supabase client initialized.")
            
            listenToAuthState()
            
        } else {
            print("🚨 ERROR: Supabase credentials not found. The client will be nil.")
            self.client = nil
        }
    }
    
    deinit {
        // Cancel the task when the service is deallocated
        authTask?.cancel()
    }
    
    /// Listens to Supabase auth events and updates the session automatically using modern Swift Concurrency.
    private func listenToAuthState() {
        authTask = Task {
            guard let client = self.client else { return }
            
            // The for-await loop correctly consumes the AsyncStream
            for await (event, session) in client.auth.authStateChanges {
                
                // This ensures UI updates happen on the main thread
                await MainActor.run {
                    self.session = session
                    self.isAuthenticated = session != nil
                    
                    switch event {
                        case .signedIn:
                            print("Auth state changed. User is now logged in.")
                        case .signedOut:
                            print("Auth state changed. User is now logged out.")
                        case .passwordRecovery, .tokenRefreshed, .userUpdated:
                            break
                        case _:
                            break
                    }
                }
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        guard let client = self.client else { return }
        try await client.auth.signIn(email: email, password: password)
    }
    
    func logout() async {
        guard let client = self.client else { return }
        do {
            try await client.auth.signOut()
        } catch {
            print("🚨 Error logging out: \(error.localizedDescription)")
        }
    }
}
