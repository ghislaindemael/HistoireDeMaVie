//
//  LoginComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.06.2025.
//


import SwiftUI

struct AuthComponent: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isExpanded: Bool
    @State private var errorMessage: String?
    @State private var isLoading = false

    @ObservedObject private var auth = SupabaseService.shared

    init(expanded: Bool) {
        _isExpanded = State(initialValue: expanded)
    }

    var body: some View {
        DisclosureGroup("Supabase Login", isExpanded: $isExpanded) {
            VStack(spacing: 5) {
                if !auth.isAuthenticated {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Logged in as:")
                        Text(auth.session?.user.email ?? "unknown")
                            .font(.headline)
                        
                        Button("Log Out") {
                            Task {
                                await auth.logout()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 1)
        )
        
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.login(email: email, password: password)
            isExpanded = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    AuthComponent(expanded: true)
}
