//
//  HomeViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var todayStats: DailyStats?
    @Published var upcomingWorkout: Workout?
    @Published var todayQuote: MotivationalQuote
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    init() {
        // Pick a random quote for today
        self.todayQuote = MotivationalQuote.defaultQuotes.randomElement() ?? MotivationalQuote.defaultQuotes[0]
    }
    
    // MARK: - Load Data
    func loadData(userId: String) async {
        isLoading = true
        
        async let profileTask: () = loadUserProfile(userId: userId)
        async let statsTask: () = loadTodayStats(userId: userId)
        async let workoutTask: () = loadUpcomingWorkout(userId: userId)
        
        _ = await (profileTask, statsTask, workoutTask)
        
        isLoading = false
    }
    
    // MARK: - Load User Profile
    private func loadUserProfile(userId: String) async {
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    // MARK: - Load Today Stats
    private func loadTodayStats(userId: String) async {
        // For now, use mock data
        // In production, fetch from Supabase
        self.todayStats = DailyStats(
            userId: userId,
            date: Date(),
            weight: 52,
            caloriesConsumed: 1240,
            mood: .good
        )
    }
    
    // MARK: - Load Upcoming Workout
    private func loadUpcomingWorkout(userId: String) async {
        // For now, use mock data
        // In production, fetch from Supabase
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 17
        components.minute = 30
        
        let trainer = Trainer(
            id: "1",
            name: "Lan Anh",
            avatarUrl: nil,
            specialty: "Yoga & Pilates"
        )
        
        self.upcomingWorkout = Workout(
            id: "1",
            title: "Full Body Tone",
            description: "Cardio nhẹ nhàng",
            category: .cardio,
            duration: 45,
            scheduledTime: calendar.date(from: components) ?? Date(),
            status: .upcoming,
            imageUrl: nil,
            trainer: trainer,
            intensity: "Nhẹ nhàng",
            caloriesBurn: 250
        )
    }
    
    // MARK: - Check In
    func checkIn() async {
        guard var workout = upcomingWorkout else { return }
        
        // Update workout status
        workout.status = .ongoing
        self.upcomingWorkout = workout
        
        // In production, update in Supabase
    }
    
    // MARK: - Greeting
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "Chào buổi sáng,"
        } else if hour < 18 {
            return "Chào buổi chiều,"
        } else {
            return "Chào buổi tối,"
        }
    }
    
    var displayName: String {
        if let name = userProfile?.displayName, !name.isEmpty {
            // Get first name
            let firstName = name.components(separatedBy: " ").last ?? name
            return firstName
        }
        return "bạn"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd 'THÁNG' MM"
        return formatter.string(from: Date()).uppercased()
    }
}

