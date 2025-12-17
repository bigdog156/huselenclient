//
//  MealLogViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class MealLogViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate: Date = Date()
    @Published var weekDates: [Date] = []
    @Published var mealLogs: [MealType: UserMealLog] = [:]
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    
    // Current editing meal
    @Published var editingMealType: MealType?
    @Published var editingNote: String = ""
    @Published var editingPhoto: UIImage?
    @Published var editingFeeling: MealFeeling?
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Computed Properties
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: selectedDate).capitalized
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // MARK: - Initialize Week Dates
    func initializeWeekDates() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        
        guard let startOfWeek = calendar.date(from: components) else { return }
        
        // Generate 7 days
        weekDates = (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
    
    // MARK: - Load Meals for Date
    func loadMeals(userId: String, for date: Date? = nil) async {
        let targetDate = date ?? selectedDate
        isLoading = true
        errorMessage = nil
        
        let dateString = DateFormatters.dateOnly.string(from: targetDate)
        
        do {
            let response: [UserMealLog] = try await supabase
                .from("user_meal_logs")
                .select()
                .eq("user_id", value: userId)
                .eq("logged_date", value: dateString)
                .execute()
                .value
            
            // Convert to dictionary by meal type
            var mealsDict: [MealType: UserMealLog] = [:]
            for meal in response {
                mealsDict[meal.mealType] = meal
            }
            self.mealLogs = mealsDict
            
        } catch {
            self.errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Save Meal Log
    func saveMealLog(
        userId: String,
        mealType: MealType,
        photo: UIImage?,
        note: String?,
        feeling: MealFeeling?
    ) async -> Bool {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        
        do {
            var photoUrl: String? = nil
            
            // Upload photo if exists
            if let photo = photo,
               let imageData = photo.jpegData(compressionQuality: 0.7) {
                let dateString = DateFormatters.dateOnly.string(from: selectedDate)
                let fileName = "\(userId)/\(dateString)_\(mealType.rawValue)_\(Date().timeIntervalSince1970).jpg"
                
                try await supabase.storage
                    .from("meal-photos")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                photoUrl = try supabase.storage
                    .from("meal-photos")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }
            
            // Get current time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let currentTime = timeFormatter.string(from: Date())
            
            // Check if meal already exists for this date
            if let existingMeal = mealLogs[mealType] {
                // Update existing meal
                var updateData: [String: AnyEncodable] = [:]
                
                if let photoUrl = photoUrl {
                    updateData["photo_url"] = AnyEncodable(photoUrl)
                }
                if let note = note, !note.isEmpty {
                    updateData["note"] = AnyEncodable(note)
                }
                if let feeling = feeling {
                    updateData["feeling"] = AnyEncodable(feeling.rawValue)
                }
                updateData["logged_time"] = AnyEncodable(currentTime)
                
                try await supabase
                    .from("user_meal_logs")
                    .update(updateData)
                    .eq("id", value: existingMeal.id ?? "")
                    .execute()
            } else {
                // Create new meal log
                let mealLog = UserMealLog(
                    userId: userId,
                    mealType: mealType,
                    photoUrl: photoUrl,
                    note: note?.isEmpty == true ? nil : note,
                    feeling: feeling,
                    loggedDate: selectedDate,
                    loggedTime: currentTime
                )
                
                try await supabase
                    .from("user_meal_logs")
                    .insert(mealLog)
                    .execute()
            }
            
            // Reload data
            await loadMeals(userId: userId)
            
            // Reset editing state
            resetEditing()
            saveSuccess = true
            isSaving = false
            
            return true
            
        } catch {
            isSaving = false
            errorMessage = "Không thể lưu: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Delete Meal Log
    func deleteMealLog(userId: String, mealType: MealType) async -> Bool {
        guard let meal = mealLogs[mealType], let mealId = meal.id else {
            return false
        }
        
        isSaving = true
        
        do {
            try await supabase
                .from("user_meal_logs")
                .delete()
                .eq("id", value: mealId)
                .execute()
            
            await loadMeals(userId: userId)
            isSaving = false
            return true
            
        } catch {
            isSaving = false
            errorMessage = "Không thể xóa: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Select Date
    func selectDate(_ date: Date, userId: String) async {
        selectedDate = date
        await loadMeals(userId: userId, for: date)
    }
    
    // MARK: - Start Editing
    func startEditing(mealType: MealType) {
        editingMealType = mealType
        
        // Load existing data if available
        if let existingMeal = mealLogs[mealType] {
            editingNote = existingMeal.note ?? ""
            editingFeeling = existingMeal.feeling
        } else {
            editingNote = ""
            editingFeeling = nil
        }
        editingPhoto = nil
    }
    
    // MARK: - Reset Editing
    func resetEditing() {
        editingMealType = nil
        editingNote = ""
        editingPhoto = nil
        editingFeeling = nil
    }
    
    // MARK: - Get Day Name
    func dayName(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
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
    
    func dayNumber(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return String(day)
    }
    
    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - AnyEncodable Helper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

