//
//  WeightLog.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation

// MARK: - Weight Input Type
enum WeightInputType: String, Codable {
    case manual = "manual"
    case photo = "photo"
    
    var displayName: String {
        switch self {
        case .manual: return "Nhập thủ công"
        case .photo: return "Đã chụp ảnh"
        }
    }
}

// MARK: - User Weight Log
struct UserWeightLog: Codable, Identifiable {
    var id: String?
    var userId: String
    var weightKg: Double
    var photoUrl: String?
    var inputType: WeightInputType?
    var loggedDate: Date
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weightKg = "weight_kg"
        case photoUrl = "photo_url"
        case inputType = "input_type"
        case loggedDate = "logged_date"
        case createdAt = "created_at"
    }
    
    // MARK: - Formatted Date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: loggedDate).capitalized
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: loggedDate)
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        inputType = try container.decodeIfPresent(WeightInputType.self, forKey: .inputType)
        
        // Handle logged_date (simple date format: yyyy-MM-dd)
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
        try container.encode(weightKg, forKey: .weightKg)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(inputType, forKey: .inputType)
        try container.encode(DateFormatters.dateOnly.string(from: loggedDate), forKey: .loggedDate)
        // Don't encode createdAt - let database handle it
    }
    
    // MARK: - Init
    init(
        id: String? = nil,
        userId: String,
        weightKg: Double,
        photoUrl: String? = nil,
        inputType: WeightInputType? = .manual,
        loggedDate: Date = Date(),
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.weightKg = weightKg
        self.photoUrl = photoUrl
        self.inputType = inputType
        self.loggedDate = loggedDate
        self.createdAt = createdAt
    }
}

// MARK: - Weight Chart Data Point
struct WeightChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: date)
    }
}

