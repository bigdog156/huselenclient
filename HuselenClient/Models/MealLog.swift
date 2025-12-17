//
//  MealLog.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import SwiftUI

// MARK: - Meal Type
enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case afternoon = "afternoon"
    case dinner = "dinner"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .breakfast: return "Bữa Sáng"
        case .lunch: return "Bữa Trưa"
        case .afternoon: return "Bữa Chiều"
        case .dinner: return "Bữa Tối"
        }
    }
    
    var shortName: String {
        switch self {
        case .breakfast: return "Sáng"
        case .lunch: return "Trưa"
        case .afternoon: return "Chiều"
        case .dinner: return "Tối"
        }
    }
    
    var placeholder: String {
        switch self {
        case .breakfast: return "Bữa sáng của bạn thế nào?"
        case .lunch: return "Bữa trưa ngon miệng chứ?"
        case .afternoon: return "Nạp chút năng lượng?"
        case .dinner: return "Bữa tối nhẹ nhàng nhé!"
        }
    }
    
    var photoPlaceholder: String {
        switch self {
        case .breakfast: return "Chụp ảnh bữa sáng"
        case .lunch: return "Chụp ảnh bữa trưa"
        case .afternoon: return "Chụp ảnh bữa chiều"
        case .dinner: return "Chụp ảnh bữa tối"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .afternoon: return "sun.haze.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .afternoon: return .purple
        case .dinner: return .indigo
        }
    }
    
    var isOptional: Bool {
        return self == .dinner
    }
    
    // Order for display
    var order: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .afternoon: return 2
        case .dinner: return 3
        }
    }
}

// MARK: - Meal Feeling
enum MealFeeling: String, CaseIterable, Codable {
    case good = "good"
    case normal = "normal"
    case tired = "tired"
    
    var icon: String {
        switch self {
        case .good: return "face.smiling.fill"
        case .normal: return "bolt.fill"
        case .tired: return "figure.walk"
        }
    }
    
    var displayName: String {
        switch self {
        case .good: return "Tốt"
        case .normal: return "Bình thường"
        case .tired: return "Mệt"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return .green
        case .normal: return .blue
        case .tired: return .orange
        }
    }
}

// MARK: - User Meal Log
struct UserMealLog: Codable, Identifiable {
    var id: String?
    var userId: String
    var mealType: MealType
    var photoUrl: String?
    var note: String?
    var feeling: MealFeeling?
    var energyLevel: String?
    var loggedDate: Date
    var loggedTime: String?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case photoUrl = "photo_url"
        case note
        case feeling
        case energyLevel = "energy_level"
        case loggedDate = "logged_date"
        case loggedTime = "logged_time"
        case createdAt = "created_at"
    }
    
    // MARK: - Formatted Time
    var formattedTime: String {
        if let time = loggedTime {
            // Parse HH:mm:ss format and return HH:mm AM/PM
            let components = time.split(separator: ":")
            if components.count >= 2,
               let hour = Int(components[0]),
               let minute = Int(components[1]) {
                let period = hour >= 12 ? "PM" : "AM"
                let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
                return String(format: "%d:%02d %@", displayHour, minute, period)
            }
        }
        return ""
    }
    
    var hasContent: Bool {
        return photoUrl != nil || (note != nil && !note!.isEmpty)
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        mealType = try container.decode(MealType.self, forKey: .mealType)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        feeling = try container.decodeIfPresent(MealFeeling.self, forKey: .feeling)
        energyLevel = try container.decodeIfPresent(String.self, forKey: .energyLevel)
        loggedTime = try container.decodeIfPresent(String.self, forKey: .loggedTime)
        
        // Handle logged_date
        if let dateString = try container.decodeIfPresent(String.self, forKey: .loggedDate) {
            loggedDate = DateFormatters.dateOnly.date(from: dateString) ?? Date()
        } else {
            loggedDate = Date()
        }
        
        // Handle created_at
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = DateFormatters.iso8601.date(from: createdAtString)
        } else {
            createdAt = nil
        }
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(mealType, forKey: .mealType)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(feeling, forKey: .feeling)
        try container.encodeIfPresent(energyLevel, forKey: .energyLevel)
        try container.encode(DateFormatters.dateOnly.string(from: loggedDate), forKey: .loggedDate)
        try container.encodeIfPresent(loggedTime, forKey: .loggedTime)
    }
    
    // MARK: - Init
    init(
        id: String? = nil,
        userId: String,
        mealType: MealType,
        photoUrl: String? = nil,
        note: String? = nil,
        feeling: MealFeeling? = nil,
        energyLevel: String? = nil,
        loggedDate: Date = Date(),
        loggedTime: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.mealType = mealType
        self.photoUrl = photoUrl
        self.note = note
        self.feeling = feeling
        self.energyLevel = energyLevel
        self.loggedDate = loggedDate
        self.loggedTime = loggedTime
        self.createdAt = createdAt
    }
}

// MARK: - Daily Meal Summary
struct DailyMealSummary {
    let date: Date
    var meals: [MealType: UserMealLog]
    
    var completedMeals: Int {
        meals.values.filter { $0.hasContent }.count
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: date).capitalized
    }
    
    func meal(for type: MealType) -> UserMealLog? {
        return meals[type]
    }
}

