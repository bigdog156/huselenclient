//
//  HomeView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCheckIn = false
    
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
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadData(userId: userId.uuidString.lowercased())
            }
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInView(
                userId: authViewModel.currentUser?.id.uuidString.lowercased() ?? "",
                workoutId: viewModel.upcomingWorkout?.id,
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
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
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
        HStack(spacing: 12) {
            // Weight Card
            StatCard(
                icon: "scalemass.fill",
                iconColor: .blue,
                iconBgColor: Color.blue.opacity(0.1),
                title: "Cân nặng",
                value: viewModel.todayStats?.weight != nil ? "\(Int(viewModel.todayStats!.weight!)) kg" : "-- kg"
            )
            
            // Calories Card
            StatCard(
                icon: "flame.fill",
                iconColor: .orange,
                iconBgColor: Color.orange.opacity(0.1),
                title: "Đã nạp",
                value: viewModel.todayStats?.caloriesConsumed != nil ? "\(viewModel.todayStats!.caloriesConsumed!.formatted()) kcal" : "-- kcal"
            )
            
            // Mood Card
            StatCard(
                icon: "face.smiling.fill",
                iconColor: .green,
                iconBgColor: Color.green.opacity(0.1),
                title: "Cảm xúc",
                value: viewModel.todayStats?.mood?.displayName ?? "Chưa có"
            )
        }
    }
    
    // MARK: - Today's Workout Section
    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hôm nay tập gì?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            if let workout = viewModel.upcomingWorkout {
                WorkoutCard(workout: workout)
            } else {
                noWorkoutCard
            }
        }
    }
    
    private var noWorkoutCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Chưa có buổi tập nào hôm nay")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Button {
                // Navigate to schedule
            } label: {
                Text("Đặt lịch tập")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                trainerDefaultAvatar
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
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

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
