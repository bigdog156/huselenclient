//
//  AddEventViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class AddEventViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var title: String = ""
    @Published var selectedTrainer: TrainerInfo?
    @Published var selectedUsers: [UserInfo] = []
    @Published var selectedDays: Set<Int> = []
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var endTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var maxCapacity: Int = 20
    @Published var location: String = ""
    @Published var notes: String = ""
    
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
        !selectedDays.isEmpty
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            errorMessage = "Vui lòng nhập tên lớp học"
            showError = true
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Get current user ID
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            // Build event data
            var eventData: [String: AnyJSON] = [
                "name": .string(title.trimmingCharacters(in: .whitespacesAndNewlines)),
                "event_date": .string(ClassEventDateFormatters.dateOnly.string(from: Date())),
                "start_time": .string(ClassEventDateFormatters.formatTime(startTime)),
                "end_time": .string(ClassEventDateFormatters.formatTime(endTime)),
                "max_capacity": .integer(maxCapacity),
                "recurring_days": .array(selectedDays.sorted().map { .integer($0) }),
                "is_recurring": .bool(isRecurring),
                "status": .string("scheduled"),
                "created_by": .string(userId.uuidString)
            ]
            
            // Add optional fields
            if let trainer = selectedTrainer {
                eventData["trainer_id"] = .string(trainer.userId.uuidString)
            }
            
            let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLocation.isEmpty {
                eventData["description"] = .string(trimmedLocation)
            }
            
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedNotes.isEmpty {
                // Append notes to description if exists
                if let existingDesc = eventData["description"], case .string(let desc) = existingDesc {
                    eventData["description"] = .string("\(desc)\n\n\(trimmedNotes)")
                } else {
                    eventData["description"] = .string(trimmedNotes)
                }
            }
            
            // Insert into class_events and get the created event
            let createdEvents: [ClassEvent] = try await supabase
                .from("class_events")
                .insert(eventData)
                .select()
                .execute()
                .value
            
            // If users are selected, add them to user_class_enrollments
            if let createdEvent = createdEvents.first, let eventId = createdEvent.id, !selectedUsers.isEmpty {
                let enrollments = selectedUsers.map { user -> [String: AnyJSON] in
                    [
                        "user_id": .string(user.userId.uuidString),
                        "class_event_id": .string(eventId.uuidString),
                        "status": .string("active")
                    ]
                }
                
                try await supabase
                    .from("user_class_enrollments")
                    .insert(enrollments)
                    .execute()
                
                print("✅ Added \(selectedUsers.count) users to class enrollment")
            }
            
            isSaving = false
            saveSuccess = true
            return true
            
        } catch {
            isSaving = false
            errorMessage = "Không thể tạo lớp học: \(error.localizedDescription)"
            showError = true
            print("Error saving event: \(error)")
            return false
        }
    }
    
    // MARK: - Reset Form
    func resetForm() {
        title = ""
        selectedTrainer = nil
        selectedUsers = []
        userSearchText = ""
        selectedDays = []
        startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        endTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        maxCapacity = 20
        location = ""
        notes = ""
        errorMessage = nil
        saveSuccess = false
    }
}

