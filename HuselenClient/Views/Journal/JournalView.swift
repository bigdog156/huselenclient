//
//  JournalView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct JournalView: View {
    let userId: String
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showEventDetail: CalendarEvent?
    @State private var showCheckInDetail: UserCheckIn?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Enrolled Classes Summary
                    if !viewModel.enrolledClasses.isEmpty {
                        enrolledClassesSummary
                    }
                    
                    // Calendar Header
                    calendarHeader
                    
                    // Weekday Header
                    weekdayHeader
                    
                    // Calendar Grid
                    calendarGrid
                    
                    // Selected Date Events
                    selectedDateSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lịch tập")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadEventsForMonth(userId: userId)
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.loadEventsForMonth(userId: userId)
                }
            }
            .sheet(item: $showEventDetail) { event in
                CalendarEventDetailSheet(
                    calendarEvent: event,
                    viewModel: viewModel,
                    userId: userId
                )
            }
            .sheet(item: $showCheckInDetail) { checkIn in
                CheckInDetailSheet(checkIn: checkIn)
            }
        }
    }
    
    // MARK: - Enrolled Classes Summary
    private var enrolledClassesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lớp học của bạn")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            ForEach(viewModel.enrolledClasses) { classEvent in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(classEvent.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text(classEvent.formattedTimeRange)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            if classEvent.isRecurring {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(viewModel.getRecurringDaysText(for: classEvent))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Calendar Header
    private var calendarHeader: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(viewModel.currentMonthYear)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(viewModel.calendarDays.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        hasEvents: viewModel.hasEvents(on: date),
                        eventsCount: viewModel.eventsCount(on: date),
                        hasCheckIn: viewModel.hasCheckIn(on: date)
                    )
                    .onTapGesture {
                        if viewModel.hasCheckIn(on: date) {
                            // Show check-in detail if available
                            showCheckInDetail = viewModel.getCheckIn(for: date)
                        } else {
                            viewModel.selectDate(date)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Selected Date Section
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date Header
            HStack {
                Text(viewModel.selectedDateFormatted)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !viewModel.selectedDateEvents.isEmpty {
                    Text("\(viewModel.selectedDateEvents.count) lớp")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.selectedDateEvents.isEmpty {
                emptyEventsView
            } else {
                // Events List
                ForEach(viewModel.selectedDateEvents) { calendarEvent in
                    CalendarEventCard(
                        calendarEvent: calendarEvent,
                        recurringDaysText: viewModel.getRecurringDaysText(for: calendarEvent.classEvent)
                    )
                    .onTapGesture {
                        showEventDetail = calendarEvent
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    private var emptyEventsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Không có lớp học")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Bạn chưa được đăng ký lớp học nào.\nVui lòng liên hệ quản lý để được thêm vào lớp.")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let eventsCount: Int
    let hasCheckIn: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 36, height: 36)
                } else if hasCheckIn {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                }
                
                // Check-in checkmark icon
                if hasCheckIn && !isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .offset(x: 12, y: -12)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
            }
            
            // Event indicator
            if hasEvents {
                HStack(spacing: 2) {
                    ForEach(0..<min(eventsCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.8) : Color.blue)
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(height: 50)
    }
}

// MARK: - Event Card
struct CalendarEventCard: View {
    let calendarEvent: CalendarEvent
    let recurringDaysText: String
    
    private var event: ClassEvent {
        calendarEvent.classEvent
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Column
            VStack(spacing: 4) {
                Text(formatTime(event.startTime))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formatTime(event.endTime))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Divider
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)
                .clipShape(Capsule())
            
            // Event Info
            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let description = event.description, !description.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text(description)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if event.isRecurring && !recurringDaysText.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                            Text(recurringDaysText)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(event.maxCapacity) người")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        // timeString is already "HH:mm:ss", just take first 5 chars
        return String(timeString.prefix(5))  // "18:00:00" -> "18:00"
    }
}

// MARK: - Event Card (Legacy - for other views)
struct EventCard: View {
    let event: ClassEvent
    let isRegistered: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Column
            VStack(spacing: 4) {
                Text(formatTime(event.startTime))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formatTime(event.endTime))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Divider
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)
                .clipShape(Capsule())
            
            // Event Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isRegistered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    Label("\(event.maxCapacity) người", systemImage: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if event.isRecurring {
                        Label("Lặp lại", systemImage: "repeat")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        // timeString is already "HH:mm:ss", just take first 5 chars
        return String(timeString.prefix(5))  // "18:00:00" -> "18:00"
    }
}

// MARK: - Event Detail Sheet
struct EventDetailSheet: View {
    let event: ClassEvent
    @ObservedObject var viewModel: CalendarViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    private var isRegistered: Bool {
        guard let eventId = event.id else { return false }
        return viewModel.isUserRegistered(for: eventId)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Header
                    VStack(spacing: 8) {
                        Text(event.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(event.formattedDate)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Event Details
                    VStack(spacing: 16) {
                        DetailRow(icon: "clock.fill", title: "Thời gian", value: event.formattedTimeRange)
                        
                        if let description = event.description, !description.isEmpty {
                            DetailRow(icon: "mappin.circle.fill", title: "Địa điểm", value: description)
                        }
                        
                        DetailRow(icon: "person.2.fill", title: "Sức chứa", value: "\(event.maxCapacity) người")
                        
                        if event.isRecurring {
                            let recurringText = event.recurringDays.map { dayName($0) }.joined(separator: ", ")
                            DetailRow(icon: "repeat", title: "Lặp lại", value: recurringText)
                        }
                        
                        DetailRow(icon: "flag.fill", title: "Trạng thái", value: event.status.displayName)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Registration Status
                    if isRegistered {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Đã đăng ký")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Bạn đã đăng ký tham gia lớp học này")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Action Button
                VStack {
                    if isRegistered {
                        Button {
                            Task {
                                isLoading = true
                                if let eventId = event.id {
                                    _ = await viewModel.cancelRegistration(eventId: eventId, userId: userId)
                                }
                                isLoading = false
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Hủy đăng ký")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                        }
                        .disabled(isLoading)
                    } else {
                        Button {
                            Task {
                                isLoading = true
                                if let eventId = event.id {
                                    _ = await viewModel.registerForEvent(eventId: eventId, userId: userId)
                                }
                                isLoading = false
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Đăng ký tham gia")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func dayName(_ day: Int) -> String {
        switch day {
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
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Calendar Event Detail Sheet
struct CalendarEventDetailSheet: View {
    let calendarEvent: CalendarEvent
    @ObservedObject var viewModel: CalendarViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss
    
    private var event: ClassEvent {
        calendarEvent.classEvent
    }
    
    private var displayDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: calendarEvent.displayDate).capitalized
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Header
                    VStack(spacing: 8) {
                        Text(event.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(displayDateFormatted)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Enrollment Status
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Đã đăng ký lớp học")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Bạn đã được đăng ký vào lớp học này")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // Event Details
                    VStack(spacing: 16) {
                        DetailRow(icon: "clock.fill", title: "Thời gian", value: event.formattedTimeRange)
                        
                        if let description = event.description, !description.isEmpty {
                            DetailRow(icon: "mappin.circle.fill", title: "Địa điểm", value: description)
                        }
                        
                        DetailRow(icon: "person.2.fill", title: "Sức chứa", value: "\(event.maxCapacity) người")
                        
                        if event.isRecurring {
                            DetailRow(
                                icon: "repeat",
                                title: "Lịch học",
                                value: viewModel.getRecurringDaysText(for: event)
                            )
                        }
                        
                        DetailRow(icon: "flag.fill", title: "Trạng thái", value: event.status.displayName)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Schedule Info
                    if event.isRecurring {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                
                                Text("Lịch học cố định")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Lớp học này diễn ra vào các ngày \(viewModel.getRecurringDaysText(for: event)) hàng tuần từ \(event.formattedTimeRange).")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Check-In Detail Sheet
struct CheckInDetailSheet: View {
    let checkIn: UserCheckIn
    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Check-in thành công")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(checkIn.formattedDate)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(checkIn.formattedTime)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    
                    // Check-in Photo
                    if let photoUrl = checkIn.photoUrl {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hình ảnh check-in")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if let loadedImage = loadedImage {
                                Image(uiImage: loadedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 300)
                                    
                                    ProgressView()
                                }
                                .task {
                                    await loadImage(from: photoUrl)
                                }
                            }
                        }
                    }
                    
                    // Check-in Details
                    VStack(spacing: 16) {
                        DetailRow(
                            icon: "number.circle.fill",
                            title: "Buổi tập",
                            value: "Buổi #\(checkIn.sessionNumber)"
                        )
                        
                        if let mood = checkIn.mood {
                            DetailRow(
                                icon: "face.smiling.fill",
                                title: "Tâm trạng",
                                value: mood.displayName
                            )
                        }
                        
                        if let note = checkIn.note, !note.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 16) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text("Ghi chú")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(note)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func loadImage(from urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    JournalView(userId: "test-user-id")
}

