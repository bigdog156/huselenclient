//
//  ManagerTabView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

enum ManagerTab: String, CaseIterable {
    case overview = "Tổng quan"
    case schedule = "Lịch học"
    case students = "Học viên"
    case profile = "Hồ sơ"
    
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .schedule: return "calendar"
        case .students: return "person.2"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .schedule: return "calendar"
        case .students: return "person.2.fill"
        case .profile: return "person.fill"
        }
    }
}

struct ManagerTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: ManagerTab = .overview
    @StateObject var profileViewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content
                Group {
                    switch selectedTab {
                    case .overview:
                        ManagerHomeView(authViewModel: authViewModel)
                    case .schedule:
                        VStack{
                            Text("Lịch học")
                        }
                    case .students:
                        StudentsListView()
                    case .profile:
                        ProfileView(authViewModel: authViewModel)
                    }
                }
                .environmentObject(profileViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                managerTabBar
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    // MARK: - Manager Tab Bar
    private var managerTabBar: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
            
            HStack(spacing: 0) {
                ForEach(ManagerTab.allCases, id: \.self) { tab in
                    ManagerTabBarButton(
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

// MARK: - Manager Tab Bar Button
struct ManagerTabBarButton: View {
    let tab: ManagerTab
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
struct StudentsListView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<10) { index in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text("H\(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Học viên \(index + 1)")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Đã check-in \(Int.random(in: 5...20)) lần")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Học viên")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ReportsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Revenue Chart Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Doanh thu tuần này")
                            .font(.system(size: 18, weight: .bold))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    Text("Biểu đồ doanh thu")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    
                    // Check-in Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Thống kê Check-in")
                            .font(.system(size: 18, weight: .bold))
                        
                        HStack(spacing: 12) {
                            ReportStatCard(
                                title: "Hôm nay",
                                value: "12",
                                color: .blue
                            )
                            
                            ReportStatCard(
                                title: "Tuần này",
                                value: "42",
                                color: .green
                            )
                            
                            ReportStatCard(
                                title: "Tháng này",
                                value: "156",
                                color: .orange
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Báo cáo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ReportStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    ManagerTabView(authViewModel: AuthViewModel())
}

