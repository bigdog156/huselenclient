//
//  ManagerCalendarViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 22/12/25.
//

import Foundation
import Supabase

@MainActor
class ManagerCalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var classEvents: [ClassEvent] = []
    @Published var selectedDateEvents: [ClassEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Student counts per event
    @Published var enrolledCounts: [UUID: Int] = [:]
    
    // Student tracking
    @Published var enrolledStudents: [EnrolledStudent] = []
    @Published var isLoadingStudents = false
    
    // Add student
    @Published var availableUsers: [UserInfo] = []
    @Published var isLoadingUsers = false
    @Published var searchText = ""
    
    private let supabase = SupabaseConfig.client
    private let calendar = Calendar.current
    
    // MARK: - Computed Properties
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    var weekdaySymbols: [String] {
        return ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    }
    
    var calendarDays: [Date?] {
        generateCalendarDays()
    }
    
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return availableUsers
        }
        return availableUsers.filter { $0.matches(searchText: searchText) }
    }
    
    // MARK: - Calendar Navigation
    func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        Task {
            await loadClassEvents()
        }
    }
    
    func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        Task {
            await loadClassEvents()
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        updateSelectedDateEvents()
    }
    
    // MARK: - Generate Calendar Days
    private func generateCalendarDays() -> [Date?] {
        var days: [Date?] = []
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        
        // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // Add empty cells for days before the first of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - Load Class Events (All events for manager)
    func loadClassEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all class events (managers can see all)
            let events: [ClassEvent] = try await supabase
                .from("class_events")
                .select()
                .neq("status", value: "cancelled")
                .order("event_date", ascending: true)
                .execute()
                .value
            
            self.classEvents = events
            
            // Load enrolled counts for all events
            await loadEnrolledCounts(for: events)
            
            updateSelectedDateEvents()
        } catch {
            print("Error loading class events: \(error)")
            errorMessage = "Không thể tải lịch học"
        }
        
        isLoading = false
    }
    
    // MARK: - Load Enrolled Counts for Events
    private func loadEnrolledCounts(for events: [ClassEvent]) async {
        let eventIds = events.compactMap { $0.id?.uuidString }
        guard !eventIds.isEmpty else { return }
        
        do {
            // Fetch all enrollments for these events
            let enrollments: [EnrollmentCount] = try await supabase
                .from("user_class_enrollments")
                .select("class_event_id")
                .in("class_event_id", values: eventIds)
                .eq("status", value: "active")
                .execute()
                .value
            
            // Count enrollments per event
            var counts: [UUID: Int] = [:]
            for enrollment in enrollments {
                counts[enrollment.classEventId, default: 0] += 1
            }
            
            self.enrolledCounts = counts
        } catch {
            print("Error loading enrolled counts: \(error)")
        }
    }
    
    // MARK: - Get Enrolled Count for Event
    func getEnrolledCount(for event: ClassEvent) -> Int {
        guard let eventId = event.id else { return 0 }
        return enrolledCounts[eventId] ?? 0
    }
    
    
    // MARK: - Update Selected Date Events
    private func updateSelectedDateEvents() {
        selectedDateEvents = classEvents.filter { event in
            event.occursOn(date: selectedDate)
        }
    }
    
    // MARK: - Check if date has events
    func hasEvents(on date: Date) -> Bool {
        return classEvents.contains { event in
            event.occursOn(date: date)
        }
    }
    
    func eventsCount(on date: Date) -> Int {
        return classEvents.filter { event in
            event.occursOn(date: date)
        }.count
    }
    
    // MARK: - Get Recurring Days Text
    func getRecurringDaysText(for event: ClassEvent) -> String {
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
    
    // MARK: - Load Enrolled Students for a Class
    func loadEnrolledStudents(for classEvent: ClassEvent) async {
        guard let eventId = classEvent.id else { return }
        
        isLoadingStudents = true
        
        do {
            // Step 1: Fetch enrollments only
            let enrollments: [EnrollmentBasic] = try await supabase
                .from("user_class_enrollments")
                .select("id, user_id, class_event_id, enrolled_at, status")
                .eq("class_event_id", value: eventId.uuidString)
                .eq("status", value: "active")
                .execute()
                .value
            
            guard !enrollments.isEmpty else {
                self.enrolledStudents = []
                isLoadingStudents = false
                return
            }
            
            // Step 2: Get user IDs from enrollments
            let userIds = enrollments.map { $0.userId.uuidString }
            
            // Step 3: Fetch profiles for these users
            let profiles: [ProfileInfo] = try await supabase
                .from("profiles")
                .select("id, user_id, display_name, avatar_url")
                .in("user_id", values: userIds)
                .execute()
                .value
            
            // Create a dictionary for quick lookup
            let profilesDict = Dictionary(uniqueKeysWithValues: profiles.map { ($0.userId, $0) })
            
            // Step 4: Load check-in count for each student and combine data
            var students: [EnrolledStudent] = []
            
            for enrollment in enrollments {
                let profile = profilesDict[enrollment.userId]
                let checkInCount = await loadCheckInCount(userId: enrollment.userId.uuidString, classEventId: eventId.uuidString)
                
                students.append(EnrolledStudent(
                    id: enrollment.id,
                    userId: enrollment.userId,
                    displayName: profile?.displayName ?? "Học viên",
                    avatarUrl: profile?.avatarUrl,
                    enrolledAt: enrollment.enrolledAt ?? Date(),
                    checkInCount: checkInCount,
                    status: enrollment.status ?? "active"
                ))
            }
            
            self.enrolledStudents = students
        } catch {
            print("Error loading enrolled students: \(error)")
            self.enrolledStudents = []
        }
        
        isLoadingStudents = false
    }
    
    // MARK: - Load Check-in Count for Student
    private func loadCheckInCount(userId: String, classEventId: String) async -> Int {
        do {
            // Count check-ins for this student
            // Using user_check_ins table - count all check-ins for the user
            let checkIns: [UserCheckInCount] = try await supabase
                .from("user_check_ins")
                .select("id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return checkIns.count
        } catch {
            print("Error loading check-in count: \(error)")
            return 0
        }
    }
    
    // MARK: - Load Available Users (for adding to class)
    func loadAvailableUsers(excluding classEventId: UUID) async {
        isLoadingUsers = true
        
        do {
            // Get all users with role 'user'
            let allUsers: [UserInfo] = try await supabase
                .from("profiles")
                .select("id, user_id, display_name, avatar_url, role")
                .eq("role", value: "user")
                .order("display_name", ascending: true)
                .execute()
                .value
            
            // Get already enrolled users for this class
            let enrolledUserIds: [EnrollmentUserId] = try await supabase
                .from("user_class_enrollments")
                .select("user_id")
                .eq("class_event_id", value: classEventId.uuidString)
                .eq("status", value: "active")
                .execute()
                .value
            
            let enrolledIds = Set(enrolledUserIds.map { $0.userId })
            
            // Filter out already enrolled users
            self.availableUsers = allUsers.filter { !enrolledIds.contains($0.userId) }
        } catch {
            print("Error loading available users: \(error)")
            self.availableUsers = []
        }
        
        isLoadingUsers = false
    }
    
    // MARK: - Add Student to Class
    func addStudentToClass(userId: UUID, classEventId: UUID, startDate: Date = Date()) async -> Bool {
        do {
            // Format start_date as yyyy-MM-dd
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            
            let enrollmentData: [String: AnyJSON] = [
                "user_id": .string(userId.uuidString),
                "class_event_id": .string(classEventId.uuidString),
                "status": .string("active"),
                "start_date": .string(startDateString)
            ]
            
            try await supabase
                .from("user_class_enrollments")
                .insert(enrollmentData)
                .execute()
            
            return true
        } catch {
            print("Error adding student to class: \(error)")
            return false
        }
    }
    
    // MARK: - Remove Student from Class
    func removeStudentFromClass(enrollmentId: UUID) async -> Bool {
        do {
            try await supabase
                .from("user_class_enrollments")
                .update(["status": "cancelled"] as [String: String])
                .eq("id", value: enrollmentId.uuidString)
                .execute()
            
            return true
        } catch {
            print("Error removing student from class: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Models

struct EnrolledStudent: Identifiable {
    let id: UUID
    let userId: UUID
    let displayName: String
    let avatarUrl: String?
    let enrolledAt: Date
    let checkInCount: Int
    let status: String
    
    var enrolledDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: enrolledAt)
    }
}

struct EnrollmentBasic: Codable {
    let id: UUID
    let userId: UUID
    let classEventId: UUID
    let enrolledAt: Date?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case classEventId = "class_event_id"
        case enrolledAt = "enrolled_at"
        case status
    }
}

struct ProfileInfo: Codable, Hashable {
    let id: UUID
    let userId: UUID
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct EnrollmentUserId: Codable {
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct EnrollmentCount: Codable {
    let classEventId: UUID
    
    enum CodingKeys: String, CodingKey {
        case classEventId = "class_event_id"
    }
}

struct UserCheckInCount: Codable {
    let id: UUID
}
