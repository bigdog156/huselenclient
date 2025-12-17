//
//  ContentView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Group {
                if !authViewModel.isAuthenticated && !authViewModel.isCheckingSession {
                    // Not logged in
                    LoginView(authViewModel: authViewModel)
                } else if authViewModel.needsOnboarding && !authViewModel.isCheckingSession {
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
                } else if !authViewModel.isCheckingSession {
                    // Logged in and onboarding completed
                    MainTabView(authViewModel: authViewModel)
                }
            }
            .opacity(showSplash ? 0 : 1)
            
            // Splash overlay
            if showSplash {
                SplashView(isCheckingSession: authViewModel.isCheckingSession)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: authViewModel.needsOnboarding)
        .onChange(of: authViewModel.isCheckingSession) { _, isChecking in
            if !isChecking {
                // Add a small delay for smoother transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Splash View
struct SplashView: View {
    let isCheckingSession: Bool
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var ringScale: CGFloat = 0.8
    @State private var ringRotation: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var particleOpacity: Double = 0
    @State private var loadingOpacity: Double = 0
    
    // Gradient colors
    private let primaryGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "0f0c29"),
            Color(hex: "302b63"),
            Color(hex: "24243e")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundGradient
                .ignoresSafeArea()
            
            // Floating particles
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { index in
                    FloatingParticle(
                        size: CGFloat.random(in: 4...12),
                        startPosition: CGPoint(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        ),
                        delay: Double(index) * 0.1
                    )
                    .opacity(particleOpacity)
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo with animated rings
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(
                            primaryGradient.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                    
                    // Rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(hex: "667eea").opacity(0.8),
                                    Color(hex: "764ba2").opacity(0.4),
                                    Color(hex: "667eea").opacity(0.1),
                                    Color(hex: "667eea").opacity(0.8)
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotation))
                        .scaleEffect(ringScale)
                    
                    // Inner glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "667eea").opacity(0.4),
                                    Color(hex: "764ba2").opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // Main icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "667eea"),
                                    Color(hex: "764ba2")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    // Yoga icon
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App title
                VStack(spacing: 12) {
                    Text("HUSELEN")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "b8c6db")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Wellness & Mindfulness")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(3)
                        .foregroundColor(Color(hex: "b8c6db").opacity(0.7))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    LoadingDots()
                    
                    if isCheckingSession {
                        Text("Đang tải...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "b8c6db").opacity(0.6))
                    }
                }
                .opacity(loadingOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1
            logoOpacity = 1
        }
        
        // Title entrance animation
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            titleOpacity = 1
            titleOffset = 0
        }
        
        // Ring scale animation
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            ringScale = 1
        }
        
        // Particles fade in
        withAnimation(.easeIn(duration: 1).delay(0.5)) {
            particleOpacity = 0.6
        }
        
        // Loading indicator
        withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
            loadingOpacity = 1
        }
        
        // Continuous animations
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Loading Dots Animation
struct LoadingDots: View {
    @State private var animatingDots = [false, false, false]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 10, height: 10)
                    .scaleEffect(animatingDots[index] ? 1.2 : 0.6)
                    .opacity(animatingDots[index] ? 1 : 0.4)
            }
        }
        .onAppear {
            for index in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
                ) {
                    animatingDots[index] = true
                }
            }
        }
    }
}

// MARK: - Floating Particle
struct FloatingParticle: View {
    let size: CGFloat
    let startPosition: CGPoint
    let delay: Double
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .position(position)
            .onAppear {
                position = startPosition
                startFloating()
            }
    }
    
    private func startFloating() {
        withAnimation(
            .easeInOut(duration: Double.random(in: 3...6))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            position = CGPoint(
                x: startPosition.x + CGFloat.random(in: -30...30),
                y: startPosition.y + CGFloat.random(in: -50...50)
            )
            opacity = Double.random(in: 0.1...0.5)
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashView(isCheckingSession: true)
}

#Preview {
    ContentView()
}
