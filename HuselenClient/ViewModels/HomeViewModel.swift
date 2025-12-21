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
    @Published var todayEvent: ClassEvent?
    @Published var todayCheckIn: UserCheckIn?
    @Published var checkInStats: CheckInStats = .empty
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
        errorMessage = nil
        
        async let profileTask: () = loadUserProfile(userId: userId)
        async let statsTask: () = loadTodayStats(userId: userId)
        async let eventTask: () = loadTodayEvent(userId: userId)
        async let checkInTask: () = loadTodayCheckIn(userId: userId)
        async let checkInStatsTask: () = loadCheckInStats(userId: userId)
        
        _ = await (profileTask, statsTask, eventTask, checkInTask, checkInStatsTask)
        
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
        let today = todayDateString()
        
        do {
            // Fetch today's weight
            let weightLogs: [WeightLogResponse] = try await supabase
                .from("user_weight_logs")
                .select()
                .eq("user_id", value: userId)
                .eq("logged_date", value: today)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            let todayWeight = weightLogs.first?.weightKg
            
            // Fetch today's meal count
            let mealLogs: [MealLogResponse] = try await supabase
                .from("user_meal_logs")
                .select()
                .eq("user_id", value: userId)
                .eq("logged_date", value: today)
                .execute()
                .value
            
            let mealCount = mealLogs.count
            
            // Fetch today's check-in mood
            let checkIns: [CheckInResponse] = try await supabase
                .from("user_check_ins")
                .select()
                .eq("user_id", value: userId)
                .gte("check_in_time", value: todayStartISO())
                .lte("check_in_time", value: todayEndISO())
                .order("check_in_time", ascending: false)
                .limit(1)
                .execute()
                .value
            
            let todayMood = checkIns.first?.mood
            
            self.todayStats = DailyStats(
                userId: userId,
                date: Date(),
                weight: todayWeight,
                caloriesConsumed: mealCount > 0 ? mealCount : nil,
                mood: todayMood != nil ? Mood(rawValue: todayMood!) : nil
            )
        } catch {
            print("Error loading today stats: \(error)")
            self.todayStats = DailyStats(
                userId: userId,
                date: Date(),
                weight: nil,
                caloriesConsumed: nil,
                mood: nil
            )
        }
    }
    
    // MARK: - Load Today Event
    private func loadTodayEvent(userId: String) async {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date()) // 1 = Sunday, 2 = Monday, etc.
        
        do {
            // First, fetch user's class enrollments
            let enrollments: [UserClassEnrollmentResponse] = try await supabase
                .from("user_class_enrollments")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .execute()
                .value
            
            guard !enrollments.isEmpty else {
                self.todayEvent = nil
                self.upcomingWorkout = nil
                return
            }
            
            // Get class IDs
            let classIds = enrollments.map { $0.classEventId }
            
            // Fetch the enrolled classes
            let enrolledClasses: [ClassEvent] = try await supabase
                .from("class_events")
                .select()
                .in("id", values: classIds)
                .eq("status", value: "scheduled")
                .execute()
                .value
            
            // Find a class that runs today (based on recurring_days or event_date)
            var todayClass: ClassEvent?
            
            for classEvent in enrolledClasses {
                if classEvent.isRecurring && classEvent.recurringDays.contains(todayWeekday) {
                    // This recurring class runs today
                    if classEvent.eventDate <= Date() { // Only show if class has started
                        todayClass = classEvent
                        break
                    }
                } else if !classEvent.isRecurring && calendar.isDateInToday(classEvent.eventDate) {
                    // Non-recurring class is today
                    todayClass = classEvent
                    break
                }
            }
            
            if let event = todayClass {
                self.todayEvent = event
                self.upcomingWorkout = convertEventToWorkout(event)
            } else {
                self.todayEvent = nil
                self.upcomingWorkout = nil
            }
        } catch {
            print("Error loading today event: \(error)")
            self.todayEvent = nil
            self.upcomingWorkout = nil
        }
    }
    
    // MARK: - Load Today Check-In
    private func loadTodayCheckIn(userId: String) async {
        do {
            let checkIns: [UserCheckIn] = try await supabase
                .from("user_check_ins")
                .select()
                .eq("user_id", value: userId)
                .gte("check_in_time", value: todayStartISO())
                .lte("check_in_time", value: todayEndISO())
                .order("check_in_time", ascending: false)
                .limit(1)
                .execute()
                .value
            
            self.todayCheckIn = checkIns.first
        } catch {
            print("Error loading today check-in: \(error)")
            self.todayCheckIn = nil
        }
    }
    
    // MARK: - Load Check-In Stats
    private func loadCheckInStats(userId: String) async {
        do {
            // Count total check-ins
            let allCheckIns: [UserCheckIn] = try await supabase
                .from("user_check_ins")
                .select()
                .eq("user_id", value: userId)
                .order("check_in_time", ascending: false)
                .execute()
                .value
            
            let totalCheckIns = allCheckIns.count
            
            // Count this month's check-ins
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
            let monthFormatter = ISO8601DateFormatter()
            let monthStart = monthFormatter.string(from: startOfMonth)
            
            let thisMonthCheckIns = allCheckIns.filter { checkIn in
                checkIn.checkInTime >= startOfMonth
            }.count
            
            // Calculate current streak
            let currentStreak = calculateCurrentStreak(checkIns: allCheckIns)
            
            self.checkInStats = CheckInStats(
                totalCheckIns: totalCheckIns,
                currentStreak: currentStreak,
                longestStreak: currentStreak, // Simplified for now
                thisMonthCheckIns: thisMonthCheckIns
            )
        } catch {
            print("Error loading check-in stats: \(error)")
            self.checkInStats = .empty
        }
    }
    
    // MARK: - Calculate Current Streak
    private func calculateCurrentStreak(checkIns: [UserCheckIn]) -> Int {
        guard !checkIns.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Get unique check-in dates
        let checkInDates = Set(checkIns.map { calendar.startOfDay(for: $0.checkInTime) })
        
        // Check if today has check-in
        if !checkInDates.contains(currentDate) {
            // Check yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Count consecutive days
        while checkInDates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    // MARK: - Convert Event to Workout
    private func convertEventToWorkout(_ event: ClassEvent) -> Workout {
        // Calculate duration in minutes
        let duration = Int(event.endTime.timeIntervalSince(event.startTime) / 60)
        
        // Combine event date with start time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: event.eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: event.startTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let scheduledTime = calendar.date(from: combinedComponents) ?? event.startTime
        
        // Map ClassEventStatus to WorkoutStatus
        let workoutStatus: WorkoutStatus
        switch event.status {
        case .scheduled:
            workoutStatus = .upcoming
        case .inProgress:
            workoutStatus = .ongoing
        case .completed:
            workoutStatus = .completed
        case .cancelled:
            workoutStatus = .cancelled
        }
        
        return Workout(
            id: event.id?.uuidString,
            title: event.name,
            description: event.description,
            category: .cardio, // Default category
            duration: max(duration, 45),
            scheduledTime: scheduledTime,
            status: workoutStatus,
            imageUrl: nil,
            trainer: nil,
            intensity: nil,
            caloriesBurn: nil
        )
    }
    
    // MARK: - Check In
    func checkIn() async {
        guard var workout = upcomingWorkout else { return }
        
        // Update workout status
        workout.status = .ongoing
        self.upcomingWorkout = workout
    }
    
    // MARK: - Check if already checked in today
    var hasCheckedInToday: Bool {
        return todayCheckIn != nil
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
    
    // MARK: - Date Helpers
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func todayStartISO() -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: startOfDay)
    }
    
    private func todayEndISO() -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: endOfDay)
    }
}

// MARK: - Response Models for Supabase
private struct WeightLogResponse: Codable {
    let id: String
    let userId: String
    let weightKg: Double
    let loggedDate: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weightKg = "weight_kg"
        case loggedDate = "logged_date"
    }
}

private struct MealLogResponse: Codable {
    let id: String
    let userId: String
    let mealType: String
    let loggedDate: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case loggedDate = "logged_date"
    }
}

private struct CheckInResponse: Codable {
    let id: String
    let userId: String
    let mood: String?
    let checkInTime: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mood
        case checkInTime = "check_in_time"
    }
}

private struct UserClassEnrollmentResponse: Codable {
    let id: String
    let userId: String
    let classEventId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case classEventId = "class_event_id"
        case status
    }
}

