//
//  ManagerCalendarView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 22/12/25.
//

import SwiftUI

struct ManagerCalendarView: View {
    @StateObject private var viewModel = ManagerCalendarViewModel()
    @State private var showEventDetail: ClassEvent?
    @State private var showAddEvent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lịch dạy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .task {
                await viewModel.loadClassEvents()
            }
            .sheet(item: $showEventDetail) { event in
                ManagerEventDetailSheet(
                    event: event,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView()
            }
        }
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
                    ManagerCalendarDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        hasEvents: viewModel.hasEvents(on: date),
                        eventsCount: viewModel.eventsCount(on: date)
                    )
                    .onTapGesture {
                        viewModel.selectDate(date)
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
                ForEach(viewModel.selectedDateEvents) { event in
                    ManagerEventCard(
                        event: event,
                        recurringDaysText: viewModel.getRecurringDaysText(for: event),
                        enrolledCount: viewModel.getEnrolledCount(for: event)
                    )
                    .onTapGesture {
                        showEventDetail = event
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
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Không có lớp học")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Ngày này chưa có lịch dạy.\nBấm nút + để thêm lớp học mới.")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Manager Calendar Day Cell
struct ManagerCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let eventsCount: Int
    
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
                            .fill(isSelected ? Color.white.opacity(0.8) : Color.purple)
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

// MARK: - Manager Event Card
struct ManagerEventCard: View {
    let event: ClassEvent
    let recurringDaysText: String
    let enrolledCount: Int
    
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
                .fill(Color.purple)
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
                        .foregroundColor(.purple)
                    }
                    
                    // Enrolled count / max capacity
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(enrolledCount)/\(event.maxCapacity)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(enrolledCount > 0 ? .green : .secondary)
                }
            }
            
            Spacer()
            
            // Enrolled Badge
            if enrolledCount > 0 {
                Text("\(enrolledCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.green))
            }
            
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

// MARK: - Manager Event Detail Sheet
struct ManagerEventDetailSheet: View {
    let event: ClassEvent
    @ObservedObject var viewModel: ManagerCalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddStudent = false
    @State private var studentToRemove: EnrolledStudent?
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Event Info Card
                    eventInfoCard
                    
                    // Students Section
                    studentsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(event.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStudent = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                    }
                }
            }
            .task {
                await viewModel.loadEnrolledStudents(for: event)
            }
            .sheet(isPresented: $showAddStudent) {
                AddStudentToClassSheet(
                    event: event,
                    viewModel: viewModel
                )
            }
            .alert("Xóa học viên", isPresented: $showRemoveConfirmation) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) {
                    if let student = studentToRemove {
                        Task {
                            if await viewModel.removeStudentFromClass(enrollmentId: student.id) {
                                await viewModel.loadEnrolledStudents(for: event)
                            }
                        }
                    }
                }
            } message: {
                if let student = studentToRemove {
                    Text("Bạn có chắc muốn xóa \(student.displayName) khỏi lớp học này?")
                }
            }
        }
    }
    
    // MARK: - Event Info Card
    private var eventInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thông tin lớp học")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Time
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("\(formatTime(event.startTime)) - \(formatTime(event.endTime))")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Location
                if let description = event.description, !description.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Schedule
                if event.isRecurring {
                    HStack(spacing: 12) {
                        Image(systemName: "repeat")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(viewModel.getRecurringDaysText(for: event))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                
                // Capacity
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Sức chứa: \(event.maxCapacity) người")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Students Section
    private var studentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Học viên")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.enrolledStudents.count) người")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isLoadingStudents {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 32)
            } else if viewModel.enrolledStudents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Chưa có học viên")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button {
                        showAddStudent = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                            Text("Thêm học viên")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Students List
                ForEach(viewModel.enrolledStudents) { student in
                    StudentRowCard(
                        student: student,
                        onRemove: {
                            studentToRemove = student
                            showRemoveConfirmation = true
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    private func formatTime(_ timeString: String) -> String {
        // timeString is already "HH:mm:ss", just take first 5 chars
        return String(timeString.prefix(5))  // "18:00:00" -> "18:00"
    }
}

// MARK: - Student Row Card
struct StudentRowCard: View {
    let student: EnrolledStudent
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = student.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(student.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    // Check-in count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("\(student.checkInCount) buổi")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // Enrolled date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text(student.enrolledDateFormatted)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 48)
            .overlay(
                Text(String(student.displayName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Add Student to Class Sheet
struct AddStudentToClassSheet: View {
    let event: ClassEvent
    @ObservedObject var viewModel: ManagerCalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUsers: Set<UUID> = []
    @State private var isSaving = false
    @State private var startDate: Date = Date()  // Date from which student will see events
    @State private var showStartDatePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Start Date Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ngày bắt đầu hiển thị lịch")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button {
                        showStartDatePicker.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            Text(formattedStartDate)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    if showStartDatePicker {
                        DatePicker(
                            "",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding(.top, 8)
                    }
                    
                    Text("Học viên sẽ chỉ thấy lịch từ ngày này trở đi")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Tìm học viên...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Users List
                if viewModel.isLoadingUsers {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Không tìm thấy học viên")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredUsers) { user in
                                UserSelectionRow(
                                    user: user,
                                    isSelected: selectedUsers.contains(user.userId)
                                )
                                .onTapGesture {
                                    toggleUser(user.userId)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                
                // Add Button
                if !selectedUsers.isEmpty {
                    Button {
                        Task {
                            await addSelectedStudents()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.badge.plus")
                                Text("Thêm \(selectedUsers.count) học viên")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(isSaving)
                    .padding(16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Thêm học viên")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
            .task {
                if let eventId = event.id {
                    await viewModel.loadAvailableUsers(excluding: eventId)
                }
            }
        }
    }
    
    private func toggleUser(_ userId: UUID) {
        if selectedUsers.contains(userId) {
            selectedUsers.remove(userId)
        } else {
            selectedUsers.insert(userId)
        }
    }
    
    private func addSelectedStudents() async {
        guard let eventId = event.id else { return }
        
        isSaving = true
        
        for userId in selectedUsers {
            _ = await viewModel.addStudentToClass(userId: userId, classEventId: eventId, startDate: startDate)
        }
        
        // Reload students
        await viewModel.loadEnrolledStudents(for: event)
        
        isSaving = false
        dismiss()
    }
    
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: startDate).capitalized
    }
}

// MARK: - User Selection Row
struct UserSelectionRow: View {
    let user: UserInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? "Học viên")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .secondary.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay(
                Text(String((user.displayName ?? "U").prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

#Preview {
    ManagerCalendarView()
}
