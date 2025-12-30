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
    
    // Nutrition tracking
    @Published var dailyNutrition: DailyNutritionSummary = DailyNutritionSummary()
    @Published var editingCalories: Int = 0
    @Published var editingProtein: Double = 0
    @Published var editingCarbs: Double = 0
    @Published var editingFat: Double = 0
    @Published var editingFoodItems: [FoodItem] = []
    @Published var showFoodDatabase = false
    @Published var searchFoodText: String = ""
    
    // AI Analysis
    @Published var isAnalyzing = false
    @Published var analysisResult: MealAnalysisResult?
    @Published var analysisError: String?
    @Published var showAnalysisResult = false
    @Published var mealDescription: String?
    @Published var healthNote: String?
    
    private let supabase = SupabaseConfig.client
    private let openAIService = OpenAIService.shared
    
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
    
    // Computed nutrition values from food items
    var calculatedCalories: Int {
        editingFoodItems.reduce(0) { $0 + $1.totalCalories }
    }
    
    var calculatedProtein: Double {
        editingFoodItems.reduce(0) { $0 + (($1.proteinG ?? 0) * $1.quantity) }
    }
    
    var calculatedCarbs: Double {
        editingFoodItems.reduce(0) { $0 + (($1.carbsG ?? 0) * $1.quantity) }
    }
    
    var calculatedFat: Double {
        editingFoodItems.reduce(0) { $0 + (($1.fatG ?? 0) * $1.quantity) }
    }
    
    // Search filtered foods
    var filteredFoods: [CommonFood] {
        if searchFoodText.isEmpty {
            return CommonFood.database
        }
        return CommonFood.database.filter { 
            $0.name.localizedCaseInsensitiveContains(searchFoodText) 
        }
    }
    
    // Foods grouped by category
    var foodsByCategory: [CommonFood.FoodCategory: [CommonFood]] {
        Dictionary(grouping: filteredFoods, by: { $0.category })
    }
    
    // MARK: - Initialize Week Dates
    func initializeWeekDates() {
        let calendar = Calendar.current
        let today = Date()
        
        // Set selectedDate to start of today for consistent date comparison
        selectedDate = calendar.startOfDay(for: today)
        
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
        
        let dateString = DateFormatters.localDateOnly.string(from: targetDate)
        
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
    
    // MARK: - Analyze Meal Image with AI
    func analyzeMealImage(_ image: UIImage) async -> MealAnalysisResult? {
        isAnalyzing = true
        analysisError = nil
        analysisResult = nil
        
        do {
            let result = try await openAIService.analyzeMealImage(image)
            
            // Update editing values with AI results
            analysisResult = result
            editingCalories = result.totalCalories
            editingProtein = result.totalProteinG
            editingCarbs = result.totalCarbsG
            editingFat = result.totalFatG
            editingFoodItems = result.toFoodItems()
            mealDescription = result.mealDescription
            healthNote = result.healthNote
            showAnalysisResult = true
            
            isAnalyzing = false
            return result
            
        } catch {
            analysisError = error.localizedDescription
            isAnalyzing = false
            return nil
        }
    }
    
    // MARK: - Save Meal With AI Analysis
    func saveMealWithAnalysis(
        userId: String,
        mealType: MealType,
        photo: UIImage?,
        note: String?
    ) async -> Bool {
        // First analyze the image if available
        if let photo = photo {
            _ = await analyzeMealImage(photo)
        }
        
        // Then save with the analyzed nutrition data
        return await saveMealWithNutrition(
            userId: userId,
            mealType: mealType,
            photo: photo,
            note: note ?? mealDescription,
            feeling: nil,
            calories: editingCalories > 0 ? editingCalories : nil,
            proteinG: editingProtein > 0 ? editingProtein : nil,
            carbsG: editingCarbs > 0 ? editingCarbs : nil,
            fatG: editingFat > 0 ? editingFat : nil,
            foodItems: editingFoodItems.isEmpty ? nil : editingFoodItems
        )
    }
    
    // MARK: - Clear Analysis Result
    func clearAnalysisResult() {
        analysisResult = nil
        analysisError = nil
        showAnalysisResult = false
        mealDescription = nil
        healthNote = nil
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
                let dateString = DateFormatters.localDateOnly.string(from: selectedDate)
                let fileName = "\(userId)/\(dateString)_\(mealType.rawValue)_\(Date().timeIntervalSince1970).jpg"
                
                try await supabase.storage
                    .from("meal-photos")
                    .upload(
                        fileName,
                        data: imageData,
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
        calculateDailyNutrition()
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
    
    // MARK: - Calculate Daily Nutrition
    func calculateDailyNutrition() {
        var summary = DailyNutritionSummary()
        
        for (_, meal) in mealLogs {
            summary.totalCalories += meal.calories ?? 0
            summary.totalProtein += meal.proteinG ?? 0
            summary.totalCarbs += meal.carbsG ?? 0
            summary.totalFat += meal.fatG ?? 0
            summary.totalFiber += meal.fiberG ?? 0
        }
        
        dailyNutrition = summary
    }
    
    // MARK: - Add Food Item
    func addFoodItem(_ food: CommonFood, quantity: Double = 1) {
        let foodItem = FoodItem(
            name: food.name,
            calories: food.calories,
            proteinG: food.proteinG,
            carbsG: food.carbsG,
            fatG: food.fatG,
            servingSize: food.servingSize,
            quantity: quantity
        )
        editingFoodItems.append(foodItem)
        updateEditingNutrition()
    }
    
    // MARK: - Remove Food Item
    func removeFoodItem(at index: Int) {
        guard index < editingFoodItems.count else { return }
        editingFoodItems.remove(at: index)
        updateEditingNutrition()
    }
    
    // MARK: - Update Food Item Quantity
    func updateFoodItemQuantity(at index: Int, quantity: Double) {
        guard index < editingFoodItems.count else { return }
        editingFoodItems[index].quantity = quantity
        updateEditingNutrition()
    }
    
    // MARK: - Update Editing Nutrition
    func updateEditingNutrition() {
        editingCalories = calculatedCalories
        editingProtein = calculatedProtein
        editingCarbs = calculatedCarbs
        editingFat = calculatedFat
    }
    
    // MARK: - Add Custom Food
    func addCustomFood(name: String, calories: Int, protein: Double = 0, carbs: Double = 0, fat: Double = 0) {
        let foodItem = FoodItem(
            name: name,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            quantity: 1
        )
        editingFoodItems.append(foodItem)
        updateEditingNutrition()
    }
    
    // MARK: - Save Meal With Nutrition
    func saveMealWithNutrition(
        userId: String,
        mealType: MealType,
        photo: UIImage?,
        note: String?,
        feeling: MealFeeling?,
        calories: Int?,
        proteinG: Double?,
        carbsG: Double?,
        fatG: Double?,
        foodItems: [FoodItem]?
    ) async -> Bool {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        
        do {
            var photoUrl: String? = nil
            
            // Upload photo if exists
            if let photo = photo,
               let imageData = photo.jpegData(compressionQuality: 0.7) {
                let dateString = DateFormatters.localDateOnly.string(from: selectedDate)
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
            
            // Encode food items to JSON
            var foodItemsJson: String? = nil
            if let items = foodItems, !items.isEmpty {
                let encoder = JSONEncoder()
                let data = try encoder.encode(items)
                foodItemsJson = String(data: data, encoding: .utf8)
            }
            
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
                if let calories = calories {
                    updateData["calories"] = AnyEncodable(calories)
                }
                if let proteinG = proteinG {
                    updateData["protein_g"] = AnyEncodable(proteinG)
                }
                if let carbsG = carbsG {
                    updateData["carbs_g"] = AnyEncodable(carbsG)
                }
                if let fatG = fatG {
                    updateData["fat_g"] = AnyEncodable(fatG)
                }
                if let foodItemsJson = foodItemsJson {
                    updateData["food_items"] = AnyEncodable(foodItemsJson)
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
                    loggedTime: currentTime,
                    calories: calories,
                    proteinG: proteinG,
                    carbsG: carbsG,
                    fatG: fatG,
                    foodItems: foodItems
                )
                
                try await supabase
                    .from("user_meal_logs")
                    .insert(mealLog)
                    .execute()
            }
            
            // Reload data and recalculate nutrition
            await loadMeals(userId: userId)
            calculateDailyNutrition()
            
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
    
    // MARK: - Reset Editing With Nutrition
    func resetEditingWithNutrition() {
        resetEditing()
        editingCalories = 0
        editingProtein = 0
        editingCarbs = 0
        editingFat = 0
        editingFoodItems = []
        searchFoodText = ""
    }
    
    // MARK: - Load Editing Data For Meal
    func loadEditingData(for mealType: MealType) {
        startEditing(mealType: mealType)
        
        if let existingMeal = mealLogs[mealType] {
            editingCalories = existingMeal.calories ?? 0
            editingProtein = existingMeal.proteinG ?? 0
            editingCarbs = existingMeal.carbsG ?? 0
            editingFat = existingMeal.fatG ?? 0
            editingFoodItems = existingMeal.foodItems ?? []
        } else {
            editingCalories = 0
            editingProtein = 0
            editingCarbs = 0
            editingFat = 0
            editingFoodItems = []
        }
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

