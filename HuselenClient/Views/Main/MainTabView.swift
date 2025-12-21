//
//  MainTabView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

enum MainTab: String, CaseIterable {
    case workout = "Tập luyện"
    case calendar = "Lịch"
    case meal = "Ăn uống"
    case weight = "Cân nặng"
    case profile = "Cá nhân"
    
    var icon: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .calendar: return "calendar"
        case .meal: return "fork.knife"
        case .weight: return "scalemass"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .calendar: return "calendar"
        case .meal: return "fork.knife"
        case .weight: return "scalemass.fill"
        case .profile: return "person.fill"
        }
    }
    
    // Tabs on left side of center button
    static var leftTabs: [MainTab] {
        [.workout, .calendar]
    }
    
    // Tabs on right side of center button
    static var rightTabs: [MainTab] {
        [.weight, .profile]
    }
}

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: MainTab = .workout
    @StateObject var profileViewModel = ProfileViewModel()
    @State private var showCheckIn = false
    
    private var userId: String {
        authViewModel.currentUser?.id.uuidString.lowercased() ?? ""
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content
                Group {
                    switch selectedTab {
                    case .workout:
                        HomeView(authViewModel: authViewModel)
                    case .calendar:
                        JournalView(userId: userId)
                    case .meal:
                        MealLogView(userId: userId)
                    case .weight:
                        WeightTrackingView(userId: userId)
                    case .profile:
                        ProfileView(authViewModel: authViewModel)
                    }
                }
                .environmentObject(profileViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                customTabBar
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInView(
                userId: userId,
                workoutId: nil,
                onCheckInComplete: {
                    // Refresh data if needed
                }
            )
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
            
            HStack(spacing: 0) {
                // Left tabs
                ForEach(MainTab.leftTabs, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
                
                // Center button (Check-in)
                centerButton
                    .offset(y: -20)
                
                // Right tabs
                ForEach(MainTab.rightTabs, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 80)
    }
    
    // MARK: - Center Button
    private var centerButton: some View {
        Button {
            showCheckIn = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}

