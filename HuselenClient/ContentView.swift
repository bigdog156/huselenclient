//
//  ContentView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isCheckingSession {
                // Loading state
                SplashView()
            } else if !authViewModel.isAuthenticated {
                // Not logged in
                LoginView(authViewModel: authViewModel)
            } else if authViewModel.needsOnboarding {
                // Needs onboarding
                OnboardingContainerView(
                    authViewModel: authViewModel,
                    showOnboarding: .init(
                        get: { authViewModel.needsOnboarding },
                        set: { newValue in
                            if !newValue {
                                authViewModel.completeOnboarding()
                            }
                        }
                    )
                )
            } else {
                // Logged in and onboarding completed
                MainTabView(authViewModel: authViewModel)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.needsOnboarding)
        .animation(.easeInOut, value: authViewModel.isCheckingSession)
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.yoga")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
}

#Preview {
    ContentView()
}
