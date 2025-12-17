//
//  UserProfile.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation

// MARK: - Gender
enum Gender: String, CaseIterable, Codable {
    case female = "female"
    case male = "male"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .female: return "Nữ"
        case .male: return "Nam"
        case .other: return "Khác"
        }
    }
}

// MARK: - Fitness Goal
enum FitnessGoal: String, CaseIterable, Codable, Identifiable {
    case loseFat = "lose_fat"
    case buildMuscle = "build_muscle"
    case health = "health"
    case reduceStress = "reduce_stress"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .loseFat: return "Giảm mỡ"
        case .buildMuscle: return "Tăng cơ"
        case .health: return "Sức khỏe"
        case .reduceStress: return "Giảm stress"
        }
    }
    
    var icon: String {
        switch self {
        case .loseFat: return "scalemass.fill"
        case .buildMuscle: return "dumbbell.fill"
        case .health: return "heart.fill"
        case .reduceStress: return "figure.mind.and.body"
        }
    }
    
    var color: String {
        switch self {
        case .loseFat: return "blue"
        case .buildMuscle: return "gray"
        case .health: return "pink"
        case .reduceStress: return "indigo"
        }
    }
}

// MARK: - Experience Level
enum ExperienceLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Mới bắt đầu"
        case .intermediate: return "Đã có kinh nghiệm"
        case .advanced: return "Chuyên nghiệp"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Chưa từng hoặc mới tập luyện"
        case .intermediate: return "Tập luyện 1-2 năm"
        case .advanced: return "Tập luyện trên 2 năm"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var id: String?
    var userId: String?
    var displayName: String?
    var avatarUrl: String?
    var gender: Gender?
    var fitnessGoal: FitnessGoal?
    var experienceLevel: ExperienceLevel?
    var height: Double?
    var weight: Double?
    var birthDate: Date?
    var onboardingCompleted: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case gender
        case fitnessGoal = "fitness_goal"
        case experienceLevel = "experience_level"
        case height
        case weight
        case birthDate = "birth_date"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: String? = nil,
        userId: String? = nil,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        gender: Gender? = nil,
        fitnessGoal: FitnessGoal? = nil,
        experienceLevel: ExperienceLevel? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        birthDate: Date? = nil,
        onboardingCompleted: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.gender = gender
        self.fitnessGoal = fitnessGoal
        self.experienceLevel = experienceLevel
        self.height = height
        self.weight = weight
        self.birthDate = birthDate
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom decoder to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        fitnessGoal = try container.decodeIfPresent(FitnessGoal.self, forKey: .fitnessGoal)
        experienceLevel = try container.decodeIfPresent(ExperienceLevel.self, forKey: .experienceLevel)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        
        // Handle birth_date (simple date format: yyyy-MM-dd)
        if let birthDateString = try container.decodeIfPresent(String.self, forKey: .birthDate) {
            birthDate = DateFormatters.dateOnly.date(from: birthDateString)
        } else {
            birthDate = nil
        }
        
        // Handle created_at and updated_at (ISO 8601 with timezone)
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = DateFormatters.iso8601.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = DateFormatters.iso8601.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    // Custom encoder to format dates properly
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(fitnessGoal, forKey: .fitnessGoal)
        try container.encodeIfPresent(experienceLevel, forKey: .experienceLevel)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encode(onboardingCompleted, forKey: .onboardingCompleted)
        
        // Encode birth_date as simple date string
        if let birthDate = birthDate {
            try container.encode(DateFormatters.dateOnly.string(from: birthDate), forKey: .birthDate)
        }
        
        // Don't encode createdAt and updatedAt - let the database handle them
    }
}

// MARK: - Date Formatters
enum DateFormatters {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

