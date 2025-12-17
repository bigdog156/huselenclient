//
//  CheckIn.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation

// MARK: - UserCheckIn
struct UserCheckIn: Codable, Identifiable {
    var id: String?
    var userId: String
    var sessionNumber: Int
    var photoUrl: String?
    var checkInTime: Date
    var note: String?
    var mood: Mood?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionNumber = "session_number"
        case photoUrl = "photo_url"
        case checkInTime = "check_in_time"
        case note
        case mood
        case createdAt = "created_at"
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: checkInTime)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: checkInTime).capitalized
    }
}

// MARK: - CheckIn Stats
struct CheckInStats: Codable {
    var totalCheckIns: Int
    var currentStreak: Int
    var longestStreak: Int
    var thisMonthCheckIns: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCheckIns = "total_check_ins"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case thisMonthCheckIns = "this_month_check_ins"
    }
    
    static let empty = CheckInStats(
        totalCheckIns: 0,
        currentStreak: 0,
        longestStreak: 0,
        thisMonthCheckIns: 0
    )
}

