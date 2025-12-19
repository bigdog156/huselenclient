//
//  PTHomeView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import SwiftUI

struct PTHomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    // Stats
    @State private var activeStudents: Int = 5
    @State private var todaySchedules: Int = 3
    @State private var pendingLogs: Int = 2
    
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
        profileViewModel.userProfile?.displayName ?? "HLV"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Stats Overview
                statsSection
                
                // Today's Schedule
                todayScheduleSection
                
                // Student Progress
                studentProgressSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Text("\(greeting),")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
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
                    colors: [Color.blue, Color.blue.opacity(0.7)],
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
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            PTStatCard(
                icon: "person.2.fill",
                value: "\(activeStudents)",
                label: "Học viên",
                color: .blue
            )
            
            PTStatCard(
                icon: "calendar.badge.clock",
                value: "\(todaySchedules)",
                label: "Buổi học",
                color: .orange
            )
            
            PTStatCard(
                icon: "doc.text.fill",
                value: "\(pendingLogs)",
                label: "Chờ xem",
                color: .purple
            )
        }
    }
    
    // MARK: - Today's Schedule Section
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lịch hôm nay")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Button("Xem tất cả") {
                    // Navigate to full schedule
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 10) {
                ForEach(0..<3) { index in
                    ScheduleCard(
                        time: "\(8 + index * 2):00 - \(9 + index * 2):00",
                        studentName: "Học viên \(index + 1)",
                        sessionType: ["1:1 Coaching", "Lớp nhóm", "Tư vấn"][index],
                        status: index == 0 ? .upcoming : .scheduled
                    )
                }
            }
        }
    }
    
    // MARK: - Student Progress Section
    private var studentProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tiến độ học viên")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Button("Xem tất cả") {
                    // Navigate to all students
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 10) {
                ForEach(0..<3) { index in
                    StudentProgressCard(
                        name: "Học viên \(index + 1)",
                        phase: index + 1,
                        mealLogged: Bool.random(),
                        workoutLogged: Bool.random()
                    )
                }
            }
        }
    }
}

// MARK: - PT Stat Card
struct PTStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Schedule Card
struct ScheduleCard: View {
    let time: String
    let studentName: String
    let sessionType: String
    let status: ScheduleStatus
    
    enum ScheduleStatus {
        case upcoming, scheduled, completed
        
        var color: Color {
            switch self {
            case .upcoming: return .green
            case .scheduled: return .blue
            case .completed: return .gray
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            Rectangle()
                .fill(status.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(studentName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(sessionType)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Student Progress Card
struct StudentProgressCard: View {
    let name: String
    let phase: Int
    let mealLogged: Bool
    let workoutLogged: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                
                Text("Tuần \(phase)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 8) {
                StatusBadge(
                    icon: "fork.knife",
                    isComplete: mealLogged,
                    label: "ĂN"
                )
                
                StatusBadge(
                    icon: "figure.run",
                    isComplete: workoutLogged,
                    label: "TẬP"
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let icon: String
    let isComplete: Bool
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : icon)
                .font(.system(size: 16))
                .foregroundColor(isComplete ? .green : .orange)
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isComplete ? .green : .orange)
        }
        .frame(width: 36)
    }
}

#Preview {
    PTHomeView(authViewModel: AuthViewModel())
        .environmentObject(ProfileViewModel())
}

