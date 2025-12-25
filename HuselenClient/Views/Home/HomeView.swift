//
//  HomeView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showCheckIn = false
    @State private var showTodayCheckInDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats Cards
                statsCardsSection
                
                // Today's Workout
                todayWorkoutSection
                
                // Motivational Quote
                quoteSection
                
                // Check-in Button
                checkInButton
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInView(
                userId: authViewModel.currentUser?.id.uuidString.lowercased() ?? "",
                workoutId: viewModel.todayEvent?.id?.uuidString,  // Pass the actual class event ID
                onCheckInComplete: {
                    // Reload data after check-in
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await viewModel.loadData(userId: userId.uuidString.lowercased())
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showTodayCheckInDetail) {
            if let checkIn = viewModel.todayCheckIn {
                TodayCheckInDetailSheet(checkIn: checkIn)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text("Chào \(viewModel.displayName),")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Profile Avatar
            profileAvatar
        }
    }
    
    private var profileAvatar: some View {
        Button {
            // Navigate to profile
        } label: {
            if let avatarUrl = viewModel.userProfile?.avatarUrl,
               let url = URL(string: avatarUrl) {
                CachedAvatarImage(
                    url: url,
                    size: 56,
                    placeholder: AnyView(defaultAvatar)
                )
            } else {
                defaultAvatar
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.75),
                        Color(red: 1.0, green: 0.9, blue: 0.85)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
    
    // MARK: - Stats Cards Section
    private var statsCardsSection: some View {
        VStack(spacing: 12) {
            // Streak Card (Full Width)
            StreakCard(
                currentStreak: viewModel.checkInStats.currentStreak,
                longestStreak: viewModel.checkInStats.longestStreak,
                totalCheckIns: viewModel.checkInStats.totalCheckIns
            )
            
            // Other Stats
            HStack(spacing: 12) {
                // Weight Card
                StatCard(
                    icon: "scalemass.fill",
                    iconColor: .blue,
                    iconBgColor: Color.blue.opacity(0.1),
                    title: "Cân nặng",
                    value: viewModel.todayStats?.weight != nil ? "\(Int(viewModel.todayStats!.weight!)) kg" : "-- kg"
                )
                
                // Meals Card (meal count instead of calories)
                StatCard(
                    icon: "fork.knife",
                    iconColor: .orange,
                    iconBgColor: Color.orange.opacity(0.1),
                    title: "Bữa ăn",
                    value: viewModel.todayStats?.caloriesConsumed != nil ? "\(viewModel.todayStats!.caloriesConsumed!) bữa" : "-- bữa"
                )
                
                // Check-in Card
                StatCard(
                    icon: "checkmark.circle.fill",
                    iconColor: viewModel.hasCheckedInToday ? .green : .gray,
                    iconBgColor: viewModel.hasCheckedInToday ? Color.green.opacity(0.1) : Color.gray.opacity(0.1),
                    title: "Check-in",
                    value: viewModel.hasCheckedInToday ? "Đã điểm danh" : "Chưa điểm danh"
                )
            }
        }
    }
    
    // MARK: - Today's Workout Section
    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lịch tập hôm nay")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !viewModel.todayEvents.isEmpty {
                    Text("\(viewModel.todayEvents.count) lớp")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            
            if viewModel.hasTodayClass {
                // Show all today's classes
                VStack(spacing: 12) {
                    ForEach(viewModel.todayEvents, id: \.id) { event in
                        TodayClassEventCard(
                            event: event,
                            hasCheckedIn: viewModel.hasCheckedInToday
                        )
                    }
                }
            } else {
                noWorkoutCard
            }
        }
    }
    
    private var noWorkoutCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Hôm nay nghỉ ngơi")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Không có lịch học hôm nay.\nHãy nghỉ ngơi và chuẩn bị cho buổi tập tiếp theo!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Quote Section
    private var quoteSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            Text("\"\(viewModel.todayQuote.content)\"")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .italic()
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Check-in Button
    private var checkInButton: some View {
        Group {
            if viewModel.hasCheckedInToday {
                // Already checked in today - Tap to view details
                Button {
                    showTodayCheckInDetail = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ĐÃ CHECK-IN HÔM NAY")
                                .font(.system(size: 16, weight: .bold))
                                .tracking(0.5)
                            
                            if let checkIn = viewModel.todayCheckIn {
                                Text("Buổi \(checkIn.sessionNumber) • \(checkIn.formattedTime) • Nhấn để xem")
                                    .font(.system(size: 13))
                                    .opacity(0.8)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                }
            } else if viewModel.hasTodayClass {
                // Has class today but not checked in yet - allow check-in
                Button {
                    showCheckIn = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                        
                        Text("CHECK-IN BUỔI TẬP")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
            } else {
                // No class today - show disabled state
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KHÔNG CÓ LỚP HÔM NAY")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(0.5)
                        
                        Text("Check-in sẽ khả dụng vào ngày có lịch học")
                            .font(.system(size: 12))
                            .opacity(0.8)
                    }
                    
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray)
                )
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let iconBgColor: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBgColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Workout Card
struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            ZStack(alignment: .topLeading) {
                // Workout Image
                Image("workout_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        // Fallback gradient if no image
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(workout.status.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                )
                .padding(16)
            }
            
            // Info Section
            VStack(spacing: 16) {
                // Title and Time
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(workout.description ?? workout.category.displayName) • \(workout.formattedDuration)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Time Badge
                    Text(workout.formattedTime)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                // Trainer Section
                if let trainer = workout.trainer {
                    HStack {
                        // Trainer Avatar
                        if let avatarUrl = trainer.avatarUrl,
                           let url = URL(string: avatarUrl) {
                            CachedAvatarImage(
                                url: url,
                                size: 44,
                                placeholder: AnyView(trainerDefaultAvatar)
                            )
                        } else {
                            trainerDefaultAvatar
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HLV PHỤ TRÁCH")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            Text(trainer.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Chat Button
                        Button {
                            // Open chat
                        } label: {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var statusColor: Color {
        switch workout.status {
        case .upcoming: return .green
        case .ongoing: return .blue
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    private var trainerDefaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Today Class Card
struct TodayClassCard: View {
    let workout: Workout
    let event: ClassEvent
    let recurringDaysText: String
    let hasCheckedIn: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with class name and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // Class name
                    Text(workout.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Schedule (recurring days)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Lịch học: \(recurringDaysText)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Check-in status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(hasCheckedIn ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(hasCheckedIn ? "Đã điểm danh" : "Chưa điểm danh")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(hasCheckedIn ? .green : .orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(hasCheckedIn ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Class details
            VStack(spacing: 16) {
                // Time
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Thời gian: \(workout.formattedTime)")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(workout.formattedDuration)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                        )
                }
                
                // Location
                if let description = event.description, !description.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Địa điểm: \(description)")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Category
                HStack(spacing: 12) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Loại hình: \(workout.category.displayName)")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Trainer
                if let trainer = workout.trainer {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("HLV: \(trainer.name)")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Today Class Event Card (Simplified card for multiple events)
struct TodayClassEventCard: View {
    let event: ClassEvent
    let hasCheckedIn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Time indicator
            VStack(spacing: 4) {
                Text(formattedStartTime)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formattedEndTime)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Vertical line
            Rectangle()
                .fill(event.isRecurring ? Color.blue : Color.purple)
                .frame(width: 3)
                .cornerRadius(1.5)
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                // Class name
                Text(event.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Time range and duration
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(event.formattedTimeRange)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    
                    if event.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                            Text(recurringDaysText)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // Location if available
                if let description = event.description, !description.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(description)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Check-in status
            VStack {
                Image(systemName: hasCheckedIn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(hasCheckedIn ? .green : .gray.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasCheckedIn ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var formattedStartTime: String {
        return event.formattedStartTime  // Use the computed property from ClassEvent
    }
    
    private var formattedEndTime: String {
        return event.formattedEndTime    // Use the computed property from ClassEvent
    }
    
    private var recurringDaysText: String {
        guard event.isRecurring else { return "" }
        
        let dayNames = event.recurringDays.sorted().compactMap { dayNumber -> String? in
            switch dayNumber {
            case 1: return "CN"
            case 2: return "T2"
            case 3: return "T3"
            case 4: return "T4"
            case 5: return "T5"
            case 6: return "T6"
            case 7: return "T7"
            default: return nil
            }
        }
        
        return dayNames.joined(separator: ", ")
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalCheckIns: Int
    
    var body: some View {
        HStack(spacing: 20) {
            // Fire Icon
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                Text("Streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Stats
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hi\u{1ec7}n t\u{1ea1}i")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("\(currentStreak)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("ng\u{00e0}y")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("K\u{1ec9} l\u{1ee5}c")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("\(longestStreak)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("ng\u{00e0}y")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Total check-ins
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("Tổng: \(totalCheckIns) lần check-in")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Today Check-In Detail Sheet
struct TodayCheckInDetailSheet: View {
    let checkIn: UserCheckIn
    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.8), Color.green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Check-in thành công!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(checkIn.formattedDate)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(checkIn.formattedTime)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    // Check-in Photo
                    if let photoUrl = checkIn.photoUrl, !photoUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text("Hình ảnh check-in")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            if let loadedImage = loadedImage {
                                Image(uiImage: loadedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 350)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 350)
                                    
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        
                                        Text("Đang tải ảnh...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .task {
                                    await loadImage(from: photoUrl)
                                }
                            }
                        }
                    }
                    
                    // Check-in Details Card
                    VStack(spacing: 16) {
                        // Session Number
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "number.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buổi tập")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text("Buổi #\(checkIn.sessionNumber)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Mood (if available)
                        if let mood = checkIn.mood {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "face.smiling.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tâm trạng")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    
                                    Text(mood.displayName)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                        }
                        
                        // Note (if available)
                        if let note = checkIn.note, !note.isEmpty {
                            HStack(alignment: .top, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "note.text")
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ghi chú")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    
                                    Text(note)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Motivational message
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text("Tuyệt vời! Hãy tiếp tục duy trì streak của bạn! 💪")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func loadImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
        .environmentObject(HomeViewModel())
}
