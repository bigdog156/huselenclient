//
//  AuthViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var needsOnboarding = false
    @Published var isCheckingSession = true
    
    private let supabase = SupabaseConfig.client
    
    init() {
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Check existing session
    func checkSession() async {
        isCheckingSession = true
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Check if user has completed onboarding
            await checkOnboardingStatus()
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            self.needsOnboarding = false
        }
        isCheckingSession = false
    }
    
    // MARK: - Check Onboarding Status
    func checkOnboardingStatus() async {
        guard let userId = currentUser?.id else {
            // No user, sign out and go to login
            await signOutSilently()
            return
        }
        
        // Use lowercase UUID to match PostgreSQL format
        let userIdString = userId.uuidString.lowercased()
        
        do {
            // Use array query instead of .single() to avoid PGRST116 error
            let response: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userIdString)
                .limit(1)
                .execute()
                .value
            
            if let profile = response.first {
                // Profile found, check if onboarding is completed
                needsOnboarding = !profile.onboardingCompleted
                print("✅ Profile found, onboardingCompleted: \(profile.onboardingCompleted)")
            } else {
                // No profile found, sign out and go to login
                print("⚠️ No profile found for user: \(userIdString), redirecting to login...")
                await signOutSilently()
            }
        } catch {
            // Error occurred, sign out and go to login
            print("❌ Error checking profile: \(error), redirecting to login...")
            await signOutSilently()
        }
    }
    
    // MARK: - Sign Out Silently (no error message)
    private func signOutSilently() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("❌ Error signing out: \(error)")
        }
        self.isAuthenticated = false
        self.currentUser = nil
        self.needsOnboarding = false
    }
    
    // MARK: - Complete Onboarding
    func completeOnboarding() {
        needsOnboarding = false
    }
    
    // MARK: - Sign In with Email
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và mật khẩu"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Check if user has completed onboarding
            await checkOnboardingStatus()
        } catch {
            self.errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up with Email
    func signUp(email: String, password: String, confirmPassword: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập đầy đủ thông tin"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Mật khẩu xác nhận không khớp"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Mật khẩu phải có ít nhất 6 ký tự"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            self.needsOnboarding = true // New user needs onboarding
        } catch {
            self.errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.needsOnboarding = false
        } catch {
            self.errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Vui lòng nhập email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            errorMessage = "Đã gửi email đặt lại mật khẩu"
        } catch {
            self.errorMessage = mapAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Error Mapping
    private func mapAuthError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid login credentials") {
            return "Email hoặc mật khẩu không đúng"
        } else if errorString.contains("email not confirmed") {
            return "Vui lòng xác nhận email của bạn"
        } else if errorString.contains("user already registered") {
            return "Email đã được đăng ký"
        } else if errorString.contains("invalid email") {
            return "Email không hợp lệ"
        } else if errorString.contains("weak password") {
            return "Mật khẩu quá yếu"
        } else {
            return "Đã xảy ra lỗi: \(error.localizedDescription)"
        }
    }
}
