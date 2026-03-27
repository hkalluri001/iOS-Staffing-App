//
//  LoginView.swift
//  StaffingAgencyApp
//
//  Created by Harshith Kalluri on 3/17/26.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Header
                        headerSection
                        
                        // Login Form
                        formSection
                        
                        // Social Login
                        socialLoginSection
                        
                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 10)
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("StaffingPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(isSignUp ? "Create your account" : "Find your next career")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Email Field
            CustomTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            
            // Password Field
            CustomSecureField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password
            )
            
            // Forgot Password
            if !isSignUp {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Submit Button
            Button(action: {
                if isSignUp {
                    viewModel.signUp(email: email, password: password)
                } else {
                    viewModel.login(email: email, password: password)
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    // MARK: - Social Login Section
    
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            HStack {
                Line()
                Text("Or continue with")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Line()
            }
            
            HStack(spacing: 20) {
                SocialButton(icon: "apple.logo", color: .black) {
                    viewModel.signInWithApple()
                }
                
                SocialButton(icon: "g.circle.fill", color: .red) {
                    viewModel.signInWithGoogle()
                }
                
                SocialButton(icon: "f.circle.fill", color: .blue) {
                    viewModel.signInWithFacebook()
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .foregroundColor(.secondary)
            
            Button(isSignUp ? "Sign In" : "Sign Up") {
                withAnimation {
                    isSignUp.toggle()
                    email = ""
                    password = ""
                }
            }
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
        .font(.subheadline)
    }
}

// MARK: - Custom Text Fields

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
            
            Spacer()
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct Line: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isSent = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                CustomTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    keyboardType: .emailAddress
                )
                
                Button(action: {
                    isSent = true
                }) {
                    Text(isSent ? "Email Sent!" : "Send Reset Link")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSent ? Color.green : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(email.isEmpty)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
