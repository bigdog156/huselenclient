//
//  MainTabView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

enum MainTab: String, CaseIterable {
    case today = "Hôm nay"
    case journal = "Nhật ký"
    case profile = "Hồ sơ"
    
    var icon: String {
        switch self {
        case .today: return "calendar"
        case .journal: return "book"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .today: return "calendar.badge.clock"
        case .journal: return "book.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: MainTab = .today
    @ObservedObject var profileViewModel = ProfileViewModel()
    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                switch selectedTab {
                case .today:
                    HomeView(authViewModel: authViewModel)
                case .journal:
                    JournalView()
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
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
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
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}

