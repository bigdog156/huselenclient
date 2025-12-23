//
//  AddEventViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Schedule Type Enum
enum ScheduleType: String, CaseIterable {
    case recurring = "recurring"
    case fixedDates = "fixed"
    
    var displayName: String {
        switch self {
        case .recurring: return "Lịch định kỳ"
        case .fixedDates: return "Ngày cố định"
        }
    }
    
    var description: String {
        switch self {
        case .recurring: return "Lặp lại theo các thứ trong tuần"
        case .fixedDates: return "Chọn các ngày cụ thể"
        }
    }
    
    var icon: String {
        switch self {
        case .recurring: return "repeat"
        case .fixedDates: return "calendar.badge.plus"
        }
    }
}

@MainActor
class AddEventViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var title: String = ""
    @Published var selectedTrainer: TrainerInfo?
    @Published var selectedUsers: [UserInfo] = []
    @Published var scheduleType: ScheduleType = .recurring
    @Published var selectedDays: Set<Int> = []  // For recurring (weekdays: 1=Sun, 2=Mon, etc.)
    @Published var selectedFixedDates: [Date] = []  // For fixed dates
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var endTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var maxCapacity: Int = 20
    @Published var location: String = ""
    @Published var notes: String = ""
    
    // End date for recurring events (optional)
    @Published var hasEndDate: Bool = false
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    // MARK: - State
    @Published var isSaving = false
    @Published var isLoadingTrainers = false
    @Published var isLoadingUsers = false
    @Published var userSearchText: String = ""
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var saveSuccess = false
    
    // MARK: - Data
    @Published var trainers: [TrainerInfo] = []
    @Published var users: [UserInfo] = []
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Computed Properties
    var isRecurring: Bool {
        scheduleType == .recurring && !selectedDays.isEmpty
    }
    
    var hasValidSchedule: Bool {
        switch scheduleType {
        case .recurring:
            return !selectedDays.isEmpty
        case .fixedDates:
            return !selectedFixedDates.isEmpty
        }
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidSchedule
    }
    
    var formattedFixedDates: String {
        guard !selectedFixedDates.isEmpty else { return "Chưa chọn ngày" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM"
        let dateStrings = selectedFixedDates.sorted().prefix(3).map { formatter.string(from: $0) }
        if selectedFixedDates.count > 3 {
            return dateStrings.joined(separator: ", ") + "... (+\(selectedFixedDates.count - 3))"
        }
        return dateStrings.joined(separator: ", ")
    }
    
    // Filter users based on search text (name or email)
    var filteredUsers: [UserInfo] {
        if userSearchText.isEmpty {
            return users
        }
        return users.filter { $0.matches(searchText: userSearchText) }
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: endTime)
    }
    
    // MARK: - Init
    init() {
        Task {
            await loadTrainers()
            await loadUsers()
        }
    }
    
    // MARK: - Load Trainers (PT users)
    func loadTrainers() async {
        isLoadingTrainers = true
        
        do {
            // Fetch users with role 'pt' from profiles
            let response: [TrainerInfo] = try await supabase
                .from("profiles")
                .select("id, user_id, display_name, avatar_url, role")
                .eq("role", value: "pt")
                .execute()
                .value
            
            trainers = response
        } catch {
            print("Error loading trainers: \(error)")
            // Continue without trainers - they can still create event
        }
        
        isLoadingTrainers = false
    }
    
    // MARK: - Load Users (all users with role 'user')
    func loadUsers() async {
        isLoadingUsers = true
        
        do {
            // Fetch users with role 'user' from profiles
            // Note: email is not in profiles table, only in auth.users (not accessible from client)
            let response: [UserInfo] = try await supabase
                .from("profiles")
                .select("id, user_id, display_name, avatar_url, role")
                .eq("role", value: "user")
                .order("display_name", ascending: true)
                .execute()
                .value
            
            users = response
            print("✅ Loaded \(users.count) users")
        } catch {
            print("❌ Error loading users: \(error)")
            // Continue without users - they can still create event
            users = []
        }
        
        isLoadingUsers = false
    }
    
    // MARK: - Search Users (client-side search by name)
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await loadUsers()
            return
        }
        
        // For now, do client-side filtering since email is not in profiles
        // In the future, you could add a server-side function or store email in profiles
        userSearchText = query
    }
    
    // MARK: - User Selection Helpers
    func isUserSelected(_ user: UserInfo) -> Bool {
        selectedUsers.contains(where: { $0.id == user.id })
    }
    
    func toggleUser(_ user: UserInfo) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }
    
    func removeUser(_ user: UserInfo) {
        selectedUsers.removeAll(where: { $0.id == user.id })
    }
    
    func clearSelectedUsers() {
        selectedUsers.removeAll()
    }
    
    // MARK: - Toggle Day Selection
    func toggleDay(_ dayId: Int) {
        if selectedDays.contains(dayId) {
            selectedDays.remove(dayId)
        } else {
            selectedDays.insert(dayId)
        }
    }
    
    func isDaySelected(_ dayId: Int) -> Bool {
        selectedDays.contains(dayId)
    }
    
    // MARK: - Fixed Dates Selection Helpers
    func toggleFixedDate(_ date: Date) {
        let calendar = Calendar.current
        if let index = selectedFixedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedFixedDates.remove(at: index)
        } else {
            selectedFixedDates.append(date)
        }
        // Sort dates
        selectedFixedDates.sort()
    }
    
    func isFixedDateSelected(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return selectedFixedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    func removeFixedDate(_ date: Date) {
        let calendar = Calendar.current
        selectedFixedDates.removeAll { calendar.isDate($0, inSameDayAs: date) }
    }
    
    func clearFixedDates() {
        selectedFixedDates.removeAll()
    }
    
    // MARK: - Capacity Controls
    func incrementCapacity() {
        if maxCapacity < 100 {
            maxCapacity += 1
        }
    }
    
    func decrementCapacity() {
        if maxCapacity > 1 {
            maxCapacity -= 1
        }
    }
    
    // MARK: - Save Event
    func save() async -> Bool {
        guard isFormValid else {
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Vui lòng nhập tên lớp học"
            } else if !hasValidSchedule {
                errorMessage = scheduleType == .recurring ? "Vui lòng chọn ít nhất một ngày trong tuần" : "Vui lòng chọn ít nhất một ngày cố định"
            }
            showError = true
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Get current user ID
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            switch scheduleType {
            case .recurring:
                // Create single recurring event
                return try await saveRecurringEvent(userId: userId)
                
            case .fixedDates:
                // Create multiple events for each fixed date
                return try await saveFixedDateEvents(userId: userId)
            }
            
        } catch {
            isSaving = false
            errorMessage = "Không thể tạo lớp học: \(error.localizedDescription)"
            showError = true
            print("Error saving event: \(error)")
            return false
        }
    }
    
    // MARK: - Save Recurring Event
    private func saveRecurringEvent(userId: UUID) async throws -> Bool {
        var eventData: [String: AnyJSON] = [
            "name": .string(title.trimmingCharacters(in: .whitespacesAndNewlines)),
            "event_date": .string(ClassEventDateFormatters.dateOnlyUTC.string(from: Date())),
            "start_time": .string(ClassEventDateFormatters.dateToTimeString(startTime)),
            "end_time": .string(ClassEventDateFormatters.dateToTimeString(endTime)),
            "max_capacity": .integer(maxCapacity),
            "recurring_days": .array(selectedDays.sorted().map { .integer($0) }),
            "is_recurring": .bool(true),
            "status": .string("scheduled"),
            "created_by": .string(userId.uuidString)
        ]
        
        // Add end_date if specified
        if hasEndDate {
            eventData["end_date"] = .string(ClassEventDateFormatters.dateOnlyUTC.string(from: endDate))
        }
        
        // Add optional fields
        if let trainer = selectedTrainer {
            eventData["trainer_id"] = .string(trainer.userId.uuidString)
        }
        
        addLocationAndNotes(to: &eventData)
        
        // Insert into class_events
        let createdEvents: [ClassEvent] = try await supabase
            .from("class_events")
            .insert(eventData)
            .select()
            .execute()
            .value
        
        // Add users to enrollment
        if let createdEvent = createdEvents.first, let eventId = createdEvent.id {
            try await addUsersToEnrollment(eventId: eventId)
        }
        
        isSaving = false
        saveSuccess = true
        return true
    }
    
    // MARK: - Save Fixed Date Events
    private func saveFixedDateEvents(userId: UUID) async throws -> Bool {
        var allEventsCreated = true
        
        for date in selectedFixedDates.sorted() {
            var eventData: [String: AnyJSON] = [
                "name": .string(title.trimmingCharacters(in: .whitespacesAndNewlines)),
                "event_date": .string(ClassEventDateFormatters.dateOnlyUTC.string(from: date)),
                "start_time": .string(ClassEventDateFormatters.dateToTimeString(startTime)),
                "end_time": .string(ClassEventDateFormatters.dateToTimeString(endTime)),
                "max_capacity": .integer(maxCapacity),
                "recurring_days": .array([]),
                "is_recurring": .bool(false),
                "status": .string("scheduled"),
                "created_by": .string(userId.uuidString)
            ]
            
            // Add optional fields
            if let trainer = selectedTrainer {
                eventData["trainer_id"] = .string(trainer.userId.uuidString)
            }
            
            addLocationAndNotes(to: &eventData)
            
            do {
                // Insert event
                let createdEvents: [ClassEvent] = try await supabase
                    .from("class_events")
                    .insert(eventData)
                    .select()
                    .execute()
                    .value
                
                // Add users to enrollment
                if let createdEvent = createdEvents.first, let eventId = createdEvent.id {
                    try await addUsersToEnrollment(eventId: eventId)
                }
            } catch {
                print("Error creating event for date \(date): \(error)")
                allEventsCreated = false
            }
        }
        
        isSaving = false
        saveSuccess = allEventsCreated
        return allEventsCreated
    }
    
    // MARK: - Helper: Add Location and Notes
    private func addLocationAndNotes(to eventData: inout [String: AnyJSON]) {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLocation.isEmpty {
            eventData["description"] = .string(trimmedLocation)
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            if let existingDesc = eventData["description"], case .string(let desc) = existingDesc {
                eventData["description"] = .string("\(desc)\n\n\(trimmedNotes)")
            } else {
                eventData["description"] = .string(trimmedNotes)
            }
        }
    }
    
    // MARK: - Helper: Add Users to Enrollment
    private func addUsersToEnrollment(eventId: UUID) async throws {
        guard !selectedUsers.isEmpty else { return }
        
        // Use today's date as start_date (or the event's start date for fixed dates)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: Date())
        
        let enrollments = selectedUsers.map { user -> [String: AnyJSON] in
            [
                "user_id": .string(user.userId.uuidString),
                "class_event_id": .string(eventId.uuidString),
                "status": .string("active"),
                "start_date": .string(startDateString)
            ]
        }
        
        try await supabase
            .from("user_class_enrollments")
            .insert(enrollments)
            .execute()
        
        print("✅ Added \(selectedUsers.count) users to class enrollment")
    }
    
    // MARK: - Reset Form
    func resetForm() {
        title = ""
        selectedTrainer = nil
        selectedUsers = []
        userSearchText = ""
        scheduleType = .recurring
        selectedDays = []
        selectedFixedDates = []
        startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        endTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        maxCapacity = 20
        location = ""
        notes = ""
        errorMessage = nil
        saveSuccess = false
    }
}
