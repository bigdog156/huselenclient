//
//  ClassEvent.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import Foundation

// MARK: - Class Event Model
struct ClassEvent: Codable, Identifiable {
    var id: UUID?
    var name: String
    var trainerId: UUID?
    var eventDate: Date
    var startTime: Date
    var endTime: Date
    var maxCapacity: Int
    var description: String?
    var recurringDays: [Int]
    var isRecurring: Bool
    var status: ClassEventStatus
    var createdBy: UUID?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case trainerId = "trainer_id"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case maxCapacity = "max_capacity"
        case description
        case recurringDays = "recurring_days"
        case isRecurring = "is_recurring"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID? = nil,
        name: String,
        trainerId: UUID? = nil,
        eventDate: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date().addingTimeInterval(3600),
        maxCapacity: Int = 20,
        description: String? = nil,
        recurringDays: [Int] = [],
        isRecurring: Bool = false,
        status: ClassEventStatus = .scheduled,
        createdBy: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.trainerId = trainerId
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.maxCapacity = maxCapacity
        self.description = description
        self.recurringDays = recurringDays
        self.isRecurring = isRecurring
        self.status = status
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        trainerId = try container.decodeIfPresent(UUID.self, forKey: .trainerId)
        maxCapacity = try container.decodeIfPresent(Int.self, forKey: .maxCapacity) ?? 20
        description = try container.decodeIfPresent(String.self, forKey: .description)
        recurringDays = try container.decodeIfPresent([Int].self, forKey: .recurringDays) ?? []
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        status = try container.decodeIfPresent(ClassEventStatus.self, forKey: .status) ?? .scheduled
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
        
        // Decode date
        if let dateString = try container.decodeIfPresent(String.self, forKey: .eventDate) {
            eventDate = ClassEventDateFormatters.dateOnly.date(from: dateString) ?? Date()
        } else {
            eventDate = Date()
        }
        
        // Decode times
        if let startTimeString = try container.decodeIfPresent(String.self, forKey: .startTime) {
            startTime = ClassEventDateFormatters.parseTime(startTimeString) ?? Date()
        } else {
            startTime = Date()
        }
        
        if let endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) {
            endTime = ClassEventDateFormatters.parseTime(endTimeString) ?? Date().addingTimeInterval(3600)
        } else {
            endTime = Date().addingTimeInterval(3600)
        }
        
        // Decode timestamps
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = ClassEventDateFormatters.iso8601.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = ClassEventDateFormatters.iso8601.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(trainerId, forKey: .trainerId)
        try container.encode(ClassEventDateFormatters.dateOnly.string(from: eventDate), forKey: .eventDate)
        try container.encode(ClassEventDateFormatters.formatTime(startTime), forKey: .startTime)
        try container.encode(ClassEventDateFormatters.formatTime(endTime), forKey: .endTime)
        try container.encode(maxCapacity, forKey: .maxCapacity)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(recurringDays, forKey: .recurringDays)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: eventDate).capitalized
    }
}

// MARK: - Class Event Status
enum ClassEventStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Đã lên lịch"
        case .inProgress: return "Đang diễn ra"
        case .completed: return "Hoàn thành"
        case .cancelled: return "Đã hủy"
        }
    }
}

// MARK: - Class Event Attendee
struct ClassEventAttendee: Codable, Identifiable {
    var id: UUID?
    var eventId: UUID
    var userId: UUID
    var checkInTime: Date?
    var status: AttendeeStatus
    var note: String?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case checkInTime = "check_in_time"
        case status
        case note
        case createdAt = "created_at"
    }
    
    init(
        id: UUID? = nil,
        eventId: UUID,
        userId: UUID,
        checkInTime: Date? = nil,
        status: AttendeeStatus = .registered,
        note: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.checkInTime = checkInTime
        self.status = status
        self.note = note
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        userId = try container.decode(UUID.self, forKey: .userId)
        status = try container.decodeIfPresent(AttendeeStatus.self, forKey: .status) ?? .registered
        note = try container.decodeIfPresent(String.self, forKey: .note)
        
        // Decode timestamps
        if let checkInTimeString = try container.decodeIfPresent(String.self, forKey: .checkInTime) {
            checkInTime = ClassEventDateFormatters.iso8601.date(from: checkInTimeString)
        } else {
            checkInTime = nil
        }
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = ClassEventDateFormatters.iso8601.date(from: createdAtString)
        } else {
            createdAt = nil
        }
    }
}

enum AttendeeStatus: String, Codable, CaseIterable {
    case registered = "registered"
    case checkedIn = "checked_in"
    case absent = "absent"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .registered: return "Đã đăng ký"
        case .checkedIn: return "Đã check-in"
        case .absent: return "Vắng mặt"
        case .cancelled: return "Đã hủy"
        }
    }
}

// MARK: - Trainer Info (for picker)
struct TrainerInfo: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var displayName: String?
    var avatarUrl: String?
    var role: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case role
    }
    
    var name: String {
        displayName ?? "HLV"
    }
}

// MARK: - User Info (for picker)
struct UserInfo: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var displayName: String?
    var email: String?
    var avatarUrl: String?
    var role: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case email
        case avatarUrl = "avatar_url"
        case role
    }
    
    var name: String {
        displayName ?? "Học viên"
    }
    
    // Search helper - matches name or email
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let lowercasedSearch = searchText.lowercased()
        if name.lowercased().contains(lowercasedSearch) {
            return true
        }
        if let email = email, email.lowercased().contains(lowercasedSearch) {
            return true
        }
        return false
    }
}

// MARK: - Date Formatters
enum ClassEventDateFormatters {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: timeString) {
            return date
        }
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Weekday
struct Weekday: Identifiable, Hashable {
    let id: Int
    let shortName: String
    let fullName: String
    
    static let all: [Weekday] = [
        Weekday(id: 2, shortName: "T2", fullName: "Thứ 2"),
        Weekday(id: 3, shortName: "T3", fullName: "Thứ 3"),
        Weekday(id: 4, shortName: "T4", fullName: "Thứ 4"),
        Weekday(id: 5, shortName: "T5", fullName: "Thứ 5"),
        Weekday(id: 6, shortName: "T6", fullName: "Thứ 6"),
        Weekday(id: 7, shortName: "T7", fullName: "Thứ 7"),
        Weekday(id: 1, shortName: "CN", fullName: "Chủ nhật")
    ]
}

