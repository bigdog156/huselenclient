//
//  CalendarViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 21/12/25.
//

import Foundation
import Supabase

// MARK: - User Class Enrollment Model
struct UserClassEnrollment: Codable, Identifiable {
    var id: UUID?
    var userId: UUID
    var classEventId: UUID
    var enrolledAt: Date?
    var status: EnrollmentStatus
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case classEventId = "class_event_id"
        case enrolledAt = "enrolled_at"
        case status
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID? = nil,
        userId: UUID,
        classEventId: UUID,
        enrolledAt: Date? = nil,
        status: EnrollmentStatus = .active,
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.classEventId = classEventId
        self.enrolledAt = enrolledAt
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum EnrollmentStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .active: return "Đang học"
        case .paused: return "Tạm nghỉ"
        case .cancelled: return "Đã hủy"
        }
    }
}

// MARK: - Calendar Event (Virtual event for display)
struct CalendarEvent: Identifiable {
    var id: String
    var classEvent: ClassEvent
    var displayDate: Date
    var isRecurringInstance: Bool
    
    init(classEvent: ClassEvent, displayDate: Date, isRecurringInstance: Bool = false) {
        self.id = "\(classEvent.id?.uuidString ?? UUID().uuidString)_\(displayDate.timeIntervalSince1970)"
        self.classEvent = classEvent
        self.displayDate = displayDate
        self.isRecurringInstance = isRecurringInstance
    }
}

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [ClassEvent] = []
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedDateEvents: [CalendarEvent] = []
    @Published var userEnrollments: [UserClassEnrollment] = []
    @Published var enrolledClasses: [ClassEvent] = []
    @Published var userAttendances: [ClassEventAttendee] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Load Events for Month
    func loadEventsForMonth(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First, load user's enrolled classes
            await loadUserEnrollments(userId: userId)
            
            // Generate calendar events for the month based on enrollments
            generateCalendarEventsForMonth()
            
            // Also fetch user's attendances
            await loadUserAttendances(userId: userId)
            
            // Update selected date events
            updateSelectedDateEvents()
        }
        
        isLoading = false
    }
    
    // MARK: - Load User Enrollments
    private func loadUserEnrollments(userId: String) async {
        do {
            // Fetch user's enrollments
            let enrollments: [UserClassEnrollment] = try await supabase
                .from("user_class_enrollments")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .execute()
                .value
            
            self.userEnrollments = enrollments
            
            // Fetch the class details for enrolled classes
            if !enrollments.isEmpty {
                let classIds = enrollments.compactMap { $0.classEventId.uuidString }
                
                let classes: [ClassEvent] = try await supabase
                    .from("class_events")
                    .select()
                    .in("id", values: classIds)
                    .execute()
                    .value
                
                self.enrolledClasses = classes
                self.events = classes
            } else {
                self.enrolledClasses = []
                self.events = []
            }
        } catch {
            print("Error loading enrollments: \(error)")
            self.errorMessage = "Không thể tải lịch học"
        }
    }
    
    // MARK: - Generate Calendar Events for Month
    private func generateCalendarEventsForMonth() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        
        var generatedEvents: [CalendarEvent] = []
        
        for classEvent in enrolledClasses {
            if classEvent.isRecurring && !classEvent.recurringDays.isEmpty {
                // Generate events for each recurring day in the month
                for dayOffset in 0..<range.count {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) {
                        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, 2 = Monday, etc.
                        
                        // Check if this weekday is in recurring_days
                        if classEvent.recurringDays.contains(weekday) {
                            // Only show events from the start date onwards
                            if date >= calendar.startOfDay(for: classEvent.eventDate) {
                                let calendarEvent = CalendarEvent(
                                    classEvent: classEvent,
                                    displayDate: date,
                                    isRecurringInstance: true
                                )
                                generatedEvents.append(calendarEvent)
                            }
                        }
                    }
                }
            } else {
                // Non-recurring event - only show on the specific date
                if calendar.isDate(classEvent.eventDate, equalTo: startOfMonth, toGranularity: .month) {
                    let calendarEvent = CalendarEvent(
                        classEvent: classEvent,
                        displayDate: classEvent.eventDate,
                        isRecurringInstance: false
                    )
                    generatedEvents.append(calendarEvent)
                }
            }
        }
        
        // Sort by date and time
        self.calendarEvents = generatedEvents.sorted { event1, event2 in
            if event1.displayDate == event2.displayDate {
                return event1.classEvent.startTime < event2.classEvent.startTime
            }
            return event1.displayDate < event2.displayDate
        }
    }
    
    // MARK: - Load User Attendances
    private func loadUserAttendances(userId: String) async {
        do {
            let attendances: [ClassEventAttendee] = try await supabase
                .from("class_event_attendees")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            self.userAttendances = attendances
        } catch {
            print("Error loading attendances: \(error)")
        }
    }
    
    // MARK: - Update Selected Date Events
    func updateSelectedDateEvents() {
        let calendar = Calendar.current
        selectedDateEvents = calendarEvents.filter { event in
            calendar.isDate(event.displayDate, inSameDayAs: selectedDate)
        }
    }
    
    // MARK: - Select Date
    func selectDate(_ date: Date) {
        selectedDate = date
        updateSelectedDateEvents()
    }
    
    // MARK: - Move to Previous Month
    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    // MARK: - Move to Next Month
    func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    // MARK: - Check if date has events
    func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return calendarEvents.contains { event in
            calendar.isDate(event.displayDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Get events count for date
    func eventsCount(on date: Date) -> Int {
        let calendar = Calendar.current
        return calendarEvents.filter { event in
            calendar.isDate(event.displayDate, inSameDayAs: date)
        }.count
    }
    
    // MARK: - Check if user is enrolled in class
    func isUserEnrolled(in classEventId: UUID) -> Bool {
        return userEnrollments.contains { $0.classEventId == classEventId }
    }
    
    // MARK: - Check if user is registered for event
    func isUserRegistered(for eventId: UUID) -> Bool {
        return userAttendances.contains { $0.eventId == eventId }
    }
    
    // MARK: - Get user attendance for event
    func getUserAttendance(for eventId: UUID) -> ClassEventAttendee? {
        return userAttendances.first { $0.eventId == eventId }
    }
    
    // MARK: - Register for Event
    func registerForEvent(eventId: UUID, userId: String) async -> Bool {
        do {
            let attendance = ClassEventAttendee(
                eventId: eventId,
                userId: UUID(uuidString: userId)!,
                status: .registered
            )
            
            try await supabase
                .from("class_event_attendees")
                .insert(attendance)
                .execute()
            
            // Reload attendances
            await loadUserAttendances(userId: userId)
            return true
        } catch {
            print("Error registering for event: \(error)")
            self.errorMessage = "Không thể đăng ký lớp học"
            return false
        }
    }
    
    // MARK: - Cancel Registration
    func cancelRegistration(eventId: UUID, userId: String) async -> Bool {
        guard let attendance = getUserAttendance(for: eventId) else { return false }
        
        do {
            try await supabase
                .from("class_event_attendees")
                .delete()
                .eq("id", value: attendance.id?.uuidString ?? "")
                .execute()
            
            // Reload attendances
            await loadUserAttendances(userId: userId)
            return true
        } catch {
            print("Error cancelling registration: \(error)")
            self.errorMessage = "Không thể hủy đăng ký"
            return false
        }
    }
    
    // MARK: - Get recurring days description
    func getRecurringDaysText(for classEvent: ClassEvent) -> String {
        guard classEvent.isRecurring, !classEvent.recurringDays.isEmpty else {
            return ""
        }
        
        let dayNames = classEvent.recurringDays.sorted().map { dayNumber -> String in
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
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    // MARK: - Calendar Grid Data
    var calendarDays: [Date?] {
        let calendar = Calendar.current
        
        // Get first day of month
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        
        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // Convert to Monday-first index (0 = Monday)
        let startOffset = (firstWeekday + 5) % 7
        
        // Get number of days in month
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let daysInMonth = range.count
        
        var days: [Date?] = []
        
        // Add empty days for offset
        for _ in 0..<startOffset {
            days.append(nil)
        }
        
        // Add all days of month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var weekdaySymbols: [String] {
        return ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    }
}
