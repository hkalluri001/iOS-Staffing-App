//
//  LoginViewModel.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var currentUser: User?
    
    // MARK: - Email/Password Login
    
    func login(email: String, password: String) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            
            // Validate credentials (replace with real API)
            if self.validateCredentials(email: email, password: password) {
                self.currentUser = User(
                    id: "user-1",
                    email: email,
                    name: "John Doe",
                    profileImage: nil
                )
                self.isLoggedIn = true
                self.saveLoginState()
            } else {
                self.errorMessage = "Invalid email or password"
                self.showError = true
            }
        }
    }
    
    func signUp(email: String, password: String) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            
            // Create new user (replace with real API)
            self.currentUser = User(
                id: "user-\(Int.random(in: 1000...9999))",
                email: email,
                name: email.components(separatedBy: "@").first ?? "User",
                profileImage: nil
            )
            self.isLoggedIn = true
            self.saveLoginState()
        }
    }
    
    // MARK: - Social Login
    
    func signInWithApple() {
        isLoading = true
        
        // Implement ASAuthorizationControllerDelegate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.currentUser = User(
                id: "apple-user",
                email: "user@icloud.com",
                name: "Apple User",
                profileImage: nil
            )
            self.isLoggedIn = true
            self.saveLoginState()
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.currentUser = User(
                id: "google-user",
                email: "user@gmail.com",
                name: "Google User",
                profileImage: nil
            )
            self.isLoggedIn = true
            self.saveLoginState()
        }
    }
    
    func signInWithFacebook() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.currentUser = User(
                id: "facebook-user",
                email: "user@facebook.com",
                name: "Facebook User",
                profileImage: nil
            )
            self.isLoggedIn = true
            self.saveLoginState()
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
    }
    
    // MARK: - Private Methods
    
    private func validateCredentials(email: String, password: String) -> Bool {
        // Demo credentials - replace with real validation
        return email.contains("@") && password.count >= 6
    }
    
    private func saveLoginState() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }
    
    func checkLoginState() {
        if UserDefaults.standard.bool(forKey: "isLoggedIn") {
            // Restore user session
            isLoggedIn = true
        }
    }
}

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let profileImage: String?
}
