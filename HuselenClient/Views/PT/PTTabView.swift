//
//  PTTabView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import SwiftUI

enum PTTab: String, CaseIterable {
    case home = "Trang chủ"
    case students = "Học viên"
    case schedule = "Lịch"
    case profile = "Hồ sơ"
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .students: return "person.2"
        case .schedule: return "calendar"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .students: return "person.2.fill"
        case .schedule: return "calendar"
        case .profile: return "person.fill"
        }
    }
}

struct PTTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: PTTab = .home
    @StateObject var profileViewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content
                Group {
                    switch selectedTab {
                    case .home:
                        PTHomeView(authViewModel: authViewModel)
                    case .students:
                        PTStudentsView()
                    case .schedule:
                        PTScheduleView()
                    case .profile:
                        ProfileView(authViewModel: authViewModel)
                    }
                }
                .environmentObject(profileViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                ptTabBar
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    // MARK: - PT Tab Bar
    private var ptTabBar: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
            
            HStack(spacing: 0) {
                ForEach(PTTab.allCases, id: \.self) { tab in
                    PTTabBarButton(
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
}

// MARK: - PT Tab Bar Button
struct PTTabBarButton: View {
    let tab: PTTab
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

// MARK: - Placeholder Views
struct PTStudentsView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<5) { index in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text("H\(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Học viên \(index + 1)")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Tuần \(Int.random(in: 1...4)) • \(["Giảm mỡ", "Tăng cơ", "Sức khỏe"].randomElement()!)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(Bool.random() ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Học viên của tôi")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PTScheduleView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Today's Schedule
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hôm nay")
                            .font(.system(size: 18, weight: .bold))
                        
                        ForEach(0..<3) { index in
                            HStack(spacing: 12) {
                                VStack {
                                    Text("\(8 + index * 2):00")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("\(9 + index * 2):00")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 50)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 3)
                                    .cornerRadius(2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Học viên \(index + 1)")
                                        .font(.system(size: 15, weight: .medium))
                                    
                                    Text("1:1 Coaching")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lịch của tôi")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PTTabView(authViewModel: AuthViewModel())
}

