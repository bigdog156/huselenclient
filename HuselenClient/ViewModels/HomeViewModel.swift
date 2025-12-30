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
    @Published var todayEvents: [ClassEvent] = []  // All events for today
    @Published var todayCheckIn: UserCheckIn?
    @Published var checkInStats: CheckInStats = .empty
    @Published var todayQuote: MotivationalQuote
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasTodayClass: Bool = false
    @Published var todayClassRecurringDays: [Int] = []
    
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
            // Fetch latest weight (not just today's - users may not log daily)
            let weightLogs: [WeightLogResponse] = try await supabase
                .from("user_weight_logs")
                .select()
                .eq("user_id", value: userId)
                .order("logged_date", ascending: false)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            let latestWeight = weightLogs.first?.weightKg
            
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
                weight: latestWeight,
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
        
        do {
            // First, fetch user's class enrollments
            let enrollments: [UserClassEnrollmentResponse] = try await supabase
                .from("user_class_enrollments")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .execute()
                .value
            
            print("📚 Found \(enrollments.count) active enrollments")
            
            guard !enrollments.isEmpty else {
                print("⚠️ No active enrollments found")
                self.todayEvent = nil
                self.todayEvents = []
                self.upcomingWorkout = nil
                self.hasTodayClass = false
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
            
            print("📅 Found \(enrolledClasses.count) scheduled classes")
            
            // Find ALL classes that run toda
            var todayClasses: [ClassEvent] = []
            let today = Date()
            let todayNormalized = calendar.startOfDay(for: today)
            
            // Use UTC formatter to parse enrollment dates from Supabase
            let dateFormatterUTC = DateFormatter()
            dateFormatterUTC.dateFormat = "yyyy-MM-dd"
            dateFormatterUTC.timeZone = TimeZone(identifier: "UTC")
            
            let dateFormatterLocal = DateFormatter()
            dateFormatterLocal.dateFormat = "yyyy-MM-dd"
            dateFormatterLocal.timeZone = TimeZone.current
            
            let todayWeekday = calendar.component(.weekday, from: today)
            print("📍 Today: \(dateFormatterLocal.string(from: today)), Weekday: \(todayWeekday)")
            
            for classEvent in enrolledClasses {
                print("\n🔎 Checking: \(classEvent.name)")
                print("   ID: \(classEvent.id?.uuidString ?? "nil")")
                print("   Event Date (from DB): \(dateFormatterLocal.string(from: classEvent.eventDate))")
                print("   Recurring: \(classEvent.isRecurring), Days: \(classEvent.recurringDays)")
                print("   Start Time: \(classEvent.startTime), End Time: \(classEvent.endTime)")
                
                // Find the enrollment for this class
                guard let enrollment = enrollments.first(where: { $0.classEventId == classEvent.id?.uuidString.lowercased() }) else {
                    print("   ❌ No enrollment found")
                    continue
                }
                
                print("   Enrollment found - ID: \(enrollment.id)")
                print("   Enrollment start_date: \(enrollment.startDate ?? "nil")")
                
                // Check if today is on or after the enrollment start_date
                if let startDateString = enrollment.startDate {
                    // Parse as UTC from Supabase
                    if let startDate = dateFormatterUTC.date(from: startDateString) {
                        let startDateNormalized = calendar.startOfDay(for: startDate)
                        if todayNormalized < startDateNormalized {
                            print("   ❌ Before start date: \(startDateString) (parsed: \(startDate))")
                            continue
                        } else {
                            print("   ✅ After or on start date")
                        }
                    } else {
                        print("   ⚠️ Could not parse start_date: \(startDateString)")
                    }
                }
                
                if classEvent.occursOn(date: today) {
                    print("   ✅ Occurs today!")
                    todayClasses.append(classEvent)
                } else {
                    print("   ❌ Does not occur today")
                }
            }
            
            // Sort by start time
            todayClasses.sort { $0.startTime < $1.startTime }  // String comparison works for "HH:mm:ss" format
            
            print("\n📊 Total today classes: \(todayClasses.count)")
            
            self.todayEvents = todayClasses
            
            if let firstEvent = todayClasses.first {
                print("✅ hasTodayClass = true")
                self.todayEvent = firstEvent
                self.upcomingWorkout = convertEventToWorkout(firstEvent)
                self.hasTodayClass = true
                self.todayClassRecurringDays = firstEvent.recurringDays
            } else {
                print("⚠️ No classes today")
                self.todayEvent = nil
                self.todayEvents = []
                self.upcomingWorkout = nil
                self.hasTodayClass = false
                self.todayClassRecurringDays = []
            }
        } catch {
            print("❌ Error loading today event: \(error)")
            self.todayEvent = nil
            self.todayEvents = []
            self.upcomingWorkout = nil
            self.hasTodayClass = false
            self.todayClassRecurringDays = []
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
        // Convert time strings to Date objects for calculations
        let startDate = event.startTimeAsDate
        let endDate = event.endTimeAsDate
        
        // Calculate duration in minutes
        let duration = Int(endDate.timeIntervalSince(startDate) / 60)
        
        // Combine event date with start time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: event.eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let scheduledTime = calendar.date(from: combinedComponents) ?? startDate
        
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
    
    // MARK: - Check if can check in
    var canCheckIn: Bool {
        return hasTodayClass && !hasCheckedInToday
    }
    
    // MARK: - Get recurring days display text
    var recurringDaysText: String {
        guard !todayClassRecurringDays.isEmpty else { return "" }
        
        let dayNames = todayClassRecurringDays.sorted().map { dayNumber -> String in
            switch dayNumber {
            case 1: return "CN"
            case 2: return "T2"
            case 3: return "T3"
            case 4: return "T4"
            case 5: return "T5"
            case 6: return "T6"
            case 7: return "T7"
            default: return ""
            }
        }
        
        return dayNames.joined(separator: ", ")
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
        return DateFormatters.localDateOnly.string(from: Date())
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
    let startDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case classEventId = "class_event_id"
        case status
        case startDate = "start_date"
    }
}

