//
//  Workout.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation

// MARK: - Workout Status
enum WorkoutStatus: String, Codable {
    case upcoming = "upcoming"
    case ongoing = "ongoing"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .upcoming: return "SẮP DIỄN RA"
        case .ongoing: return "ĐANG DIỄN RA"
        case .completed: return "ĐÃ HOÀN THÀNH"
        case .cancelled: return "ĐÃ HỦY"
        }
    }
    
    var dotColor: String {
        switch self {
        case .upcoming: return "green"
        case .ongoing: return "blue"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Workout Category
enum WorkoutCategory: String, Codable, CaseIterable {
    case cardio = "cardio"
    case strength = "strength"
    case yoga = "yoga"
    case hiit = "hiit"
    case stretching = "stretching"
    case pilates = "pilates"
    
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Tăng cường sức mạnh"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .stretching: return "Giãn cơ"
        case .pilates: return "Pilates"
        }
    }
    
    var icon: String {
        switch self {
        case .cardio: return "heart.circle.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .hiit: return "flame.fill"
        case .stretching: return "figure.flexibility"
        case .pilates: return "figure.pilates"
        }
    }
}

// MARK: - Trainer
struct Trainer: Codable, Identifiable {
    var id: String?
    var name: String
    var avatarUrl: String?
    var specialty: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarUrl = "avatar_url"
        case specialty
    }
}

// MARK: - Workout
struct Workout: Codable, Identifiable {
    var id: String?
    var title: String
    var description: String?
    var category: WorkoutCategory
    var duration: Int // in minutes
    var scheduledTime: Date
    var status: WorkoutStatus
    var imageUrl: String?
    var trainer: Trainer?
    var intensity: String?
    var caloriesBurn: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case duration
        case scheduledTime = "scheduled_time"
        case status
        case imageUrl = "image_url"
        case trainer
        case intensity
        case caloriesBurn = "calories_burn"
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }
    
    var formattedDuration: String {
        return "\(duration) phút"
    }
}

// MARK: - Mood
enum Mood: String, Codable, CaseIterable {
    case veryBad = "very_bad"
    case bad = "bad"
    case neutral = "neutral"
    case good = "good"
    case veryGood = "very_good"
    
    var displayName: String {
        switch self {
        case .veryBad: return "Rất tệ"
        case .bad: return "Không tốt"
        case .neutral: return "Bình thường"
        case .good: return "Tích cực"
        case .veryGood: return "Tuyệt vời"
        }
    }
    
    var icon: String {
        switch self {
        case .veryBad: return "face.dashed"
        case .bad: return "face.smiling.inverse"
        case .neutral: return "face.smiling"
        case .good: return "face.smiling.fill"
        case .veryGood: return "star.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .veryBad: return "red"
        case .bad: return "orange"
        case .neutral: return "gray"
        case .good: return "green"
        case .veryGood: return "blue"
        }
    }
}

// MARK: - Daily Stats
struct DailyStats: Codable {
    var id: String?
    var userId: String?
    var date: Date
    var weight: Double?
    var caloriesConsumed: Int?
    var caloriesBurned: Int?
    var mood: Mood?
    var workoutsCompleted: Int?
    var stepsCount: Int?
    var waterIntake: Double? // in liters
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case weight
        case caloriesConsumed = "calories_consumed"
        case caloriesBurned = "calories_burned"
        case mood
        case workoutsCompleted = "workouts_completed"
        case stepsCount = "steps_count"
        case waterIntake = "water_intake"
    }
}

// MARK: - Motivational Quote
struct MotivationalQuote: Codable, Identifiable {
    var id: String?
    var content: String
    var author: String?
    
    static let defaultQuotes: [MotivationalQuote] = [
        MotivationalQuote(id: "1", content: "Hãy lắng nghe cơ thể bạn. Một buổi tập nhẹ nhàng tốt hơn là không tập gì cả.", author: nil),
        MotivationalQuote(id: "2", content: "Mỗi bước tiến nhỏ đều đáng giá. Hãy kiên trì!", author: nil),
        MotivationalQuote(id: "3", content: "Sức khỏe là tài sản quý giá nhất.", author: nil),
        MotivationalQuote(id: "4", content: "Hôm nay bạn tập luyện, ngày mai bạn mạnh mẽ hơn.", author: nil),
        MotivationalQuote(id: "5", content: "Đừng so sánh với người khác, hãy so sánh với chính mình ngày hôm qua.", author: nil)
    ]
}

