//
//  ManagerHomeView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ManagerHomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    // State
    @State private var showAddEvent = false
    @State private var checkInCount: Int = 42
    @State private var checkInGrowth: Double = 15
    @State private var newStudentsCount: Int = 12
    @State private var newStudentsGrowth: Int = 5
    @State private var mealLogCount: Int = 128
    @State private var averageWeightChange: Double = -0.8
    
    // Feeling stats
    @State private var goodFeelingPercent: Int = 65
    @State private var neutralFeelingPercent: Int = 25
    @State private var tiredFeelingPercent: Int = 10
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Chào buổi sáng"
        } else if hour < 18 {
            return "Chào buổi chiều"
        } else {
            return "Chào buổi tối"
        }
    }
    
    private var displayName: String {
        profileViewModel.userProfile?.displayName ?? "Quản lý"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd 'THÁNG' M"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // Stats Cards
                statsCardsSection
                
                // Feeling Summary
                feelingSummarySection
                
                // Detailed Reports
                detailedReportsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Text("Chào \(displayName),")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Avatar
            avatarView
        }
    }
    
    private var avatarView: some View {
        Group {
            if let avatarUrl = profileViewModel.userProfile?.avatarUrl,
               let url = URL(string: avatarUrl) {
                CachedAvatarImage(
                    url: url,
                    size: 56,
                    placeholder: AnyView(
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(ProgressView())
                    )
                )
            } else {
                defaultAvatar
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thao tác nhanh")
                .font(.system(size: 20, weight: .bold))
            
            HStack(spacing: 12) {
                // Create Event Button
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Tạo lớp học",
                    color: .blue
                ) {
                    showAddEvent = true
                }
                
                // View Schedule Button
                QuickActionButton(
                    icon: "calendar",
                    title: "Lịch học",
                    color: .orange
                ) {
                    // TODO: Navigate to schedule
                }
                
                // Check-in Button
                QuickActionButton(
                    icon: "qrcode.viewfinder",
                    title: "Check-in",
                    color: .green
                ) {
                    // TODO: Navigate to check-in
                }
            }
        }
    }
    
    // MARK: - Stats Cards Section
    private var statsCardsSection: some View {
        VStack(spacing: 12) {
            // First row
            HStack(spacing: 12) {
                // Check-in Card
                StatsCard(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "CHECK-IN",
                    value: "\(checkInCount)",
                    badge: "+\(Int(checkInGrowth))%",
                    badgeColor: .green
                )
                
                // New Students Card
                StatsCard(
                    icon: "person.badge.plus",
                    iconColor: .orange,
                    title: "HỌC VIÊN MỚI",
                    value: "\(newStudentsCount)",
                    badge: "+\(newStudentsGrowth)",
                    badgeColor: .blue
                )
            }
            
            // Second row
            HStack(spacing: 12) {
                // Meal Log Card
                StatsCard(
                    icon: "fork.knife.circle.fill",
                    iconColor: .orange,
                    title: "NHẬT KÝ ĂN",
                    value: "\(mealLogCount)",
                    badge: nil,
                    badgeColor: nil
                )
                
                // Weight Change Card
                StatsCard(
                    icon: "scalemass.fill",
                    iconColor: .purple,
                    title: "CÂN NẶNG TB",
                    value: String(format: "%.1f", averageWeightChange),
                    valueSuffix: " kg",
                    badge: "Tuần",
                    badgeColor: .blue
                )
            }
        }
    }
    
    // MARK: - Feeling Summary Section
    private var feelingSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tổng hợp cảm nhận")
                .font(.system(size: 20, weight: .bold))
            
            VStack(spacing: 16) {
                FeelingProgressRow(
                    icon: "face.smiling.fill",
                    iconColor: .green,
                    title: "Tốt / Hào hứng",
                    percentage: goodFeelingPercent,
                    barColor: .green
                )
                
                FeelingProgressRow(
                    icon: "face.smiling",
                    iconColor: .yellow,
                    title: "Bình thường",
                    percentage: neutralFeelingPercent,
                    barColor: .yellow
                )
                
                FeelingProgressRow(
                    icon: "face.dashed",
                    iconColor: .red,
                    title: "Mệt mỏi",
                    percentage: tiredFeelingPercent,
                    barColor: .red
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Detailed Reports Section
    private var detailedReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Báo cáo chi tiết")
                .font(.system(size: 20, weight: .bold))
            
            VStack(spacing: 12) {
                ReportMenuItem(
                    icon: "chart.bar.fill",
                    iconBackgroundColor: Color.blue.opacity(0.15),
                    iconColor: .blue,
                    title: "Báo cáo doanh thu",
                    subtitle: "Thống kê theo tuần"
                ) {
                    // Navigate to revenue report
                }
                
                ReportMenuItem(
                    icon: "person.2.fill",
                    iconBackgroundColor: Color.purple.opacity(0.15),
                    iconColor: .purple,
                    title: "Quản lý lớp học",
                    subtitle: "Lịch học & Check-in"
                ) {
                    // Navigate to class management
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var valueSuffix: String = ""
    let badge: String?
    let badgeColor: Color?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                if let badge = badge, let badgeColor = badgeColor {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(0.15))
                        )
                }
            }
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                if !valueSuffix.isEmpty {
                    Text(valueSuffix)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Feeling Progress Row
struct FeelingProgressRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let percentage: Int
    let barColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Report Menu Item
struct ReportMenuItem: View {
    let icon: String
    let iconBackgroundColor: Color
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBackgroundColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

#Preview {
    ManagerHomeView(authViewModel: AuthViewModel())
        .environmentObject(ProfileViewModel())
}

