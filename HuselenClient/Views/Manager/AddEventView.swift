//
//  AddEventView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 19/12/25.
//

import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddEventViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // General Info Section
                    generalInfoSection
                    
                    // Schedule Section
                    scheduleSection
                    
                    // Other Details Section
                    otherDetailsSection
                    
                    // Notes Section
                    notesSection
                    
                    // Create Button
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tạo Lớp học mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Lỗi", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Đã xảy ra lỗi")
        }
    }
    
    // MARK: - General Info Section
    private var generalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("THÔNG TIN CHUNG")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(0.5)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Class Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tên lớp học")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Ví dụ: Yoga Hatha Sáng", text: $viewModel.title)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                // Trainer Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Huấn luyện viên phụ trách")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TrainerPickerButton(
                        selectedTrainer: $viewModel.selectedTrainer,
                        trainers: viewModel.trainers,
                        isLoading: viewModel.isLoadingTrainers
                    )
                }
                
                // User Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Học viên tham gia")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    UserPickerButton(
                        selectedUsers: $viewModel.selectedUsers,
                        users: viewModel.users,
                        isLoading: viewModel.isLoadingUsers
                    )
                }
            }
        }
    }
    
    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("LỊCH TRÌNH")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(0.5)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Schedule Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Loại lịch trình")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(ScheduleType.allCases, id: \.rawValue) { type in
                            ScheduleTypeButton(
                                type: type,
                                isSelected: viewModel.scheduleType == type
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.scheduleType = type
                                }
                            }
                        }
                    }
                }
                
                // Conditional Schedule Content
                if viewModel.scheduleType == .recurring {
                    recurringScheduleContent
                } else {
                    fixedDatesScheduleContent
                }
                
                // Time Selection (common for both)
                timeSelectionContent
            }
        }
    }
    
    // MARK: - Recurring Schedule Content
    private var recurringScheduleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lặp lại vào các ngày")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            // Weekday Chips
            HStack(spacing: 8) {
                ForEach(Weekday.all) { day in
                    WeekdayChip(
                        day: day,
                        isSelected: viewModel.isDaySelected(day.id)
                    ) {
                        viewModel.toggleDay(day.id)
                    }
                }
            }
            
            Text("Lớp học sẽ tự động tạo lịch cho các ngày đã chọn")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 8)
            
            // End Date Option
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.hasEndDate) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ngày kết thúc")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Lớp học sẽ kết thúc vào ngày này")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tint(.blue)
                
                if viewModel.hasEndDate {
                    DatePicker(
                        "Kết thúc vào",
                        selection: $viewModel.endDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Fixed Dates Schedule Content
    private var fixedDatesScheduleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chọn các ngày cố định")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !viewModel.selectedFixedDates.isEmpty {
                    Button {
                        viewModel.clearFixedDates()
                    } label: {
                        Text("Xóa tất cả")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Date Picker Button
            FixedDatesPickerButton(
                selectedDates: $viewModel.selectedFixedDates,
                formattedText: viewModel.formattedFixedDates
            )
            
            // Selected Dates Display
            if !viewModel.selectedFixedDates.isEmpty {
                selectedDatesChips
            }
            
            Text("Mỗi ngày sẽ tạo một buổi học riêng biệt")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Selected Dates Chips
    private var selectedDatesChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.selectedFixedDates.sorted(), id: \.self) { date in
                    FixedDateChip(date: date) {
                        viewModel.removeFixedDate(date)
                    }
                }
            }
        }
    }
    
    // MARK: - Time Selection Content
    private var timeSelectionContent: some View {
        HStack(spacing: 16) {
            // Start Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Bắt đầu")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                TimePickerButton(
                    time: $viewModel.startTime,
                    label: viewModel.formattedStartTime
                )
            }
            .frame(maxWidth: .infinity)
            
            // End Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Kết thúc")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                TimePickerButton(
                    time: $viewModel.endTime,
                    label: viewModel.formattedEndTime
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Other Details Section
    private var otherDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("CHI TIẾT KHÁC")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(0.5)
            }
            
            VStack(spacing: 16) {
                // Capacity
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Số lượng tối đa")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Số học viên giới hạn")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Stepper
                    HStack(spacing: 16) {
                        Button {
                            viewModel.decrementCapacity()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Text("\(viewModel.maxCapacity)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(minWidth: 40)
                        
                        Button {
                            viewModel.incrementCapacity()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Địa điểm")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Phòng tập, địa chỉ...", text: $viewModel.location)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ghi chú")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextEditor(text: $viewModel.notes)
                .font(.system(size: 16))
                .frame(minHeight: 100)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("hoặc dụng cụ cần chuẩn bị...")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button {
            Task {
                let success = await viewModel.save()
                if success {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                }
                
                Text("Tạo lớp học")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isSaving || !viewModel.isFormValid)
        .opacity(viewModel.isFormValid ? 1 : 0.6)
    }
}

// MARK: - Weekday Chip
struct WeekdayChip: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemBackground))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trainer Picker Button
struct TrainerPickerButton: View {
    @Binding var selectedTrainer: TrainerInfo?
    let trainers: [TrainerInfo]
    let isLoading: Bool
    
    @State private var showPicker = false
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
                Text(selectedTrainer?.name ?? "Chọn HLV")
                    .font(.system(size: 16))
                    .foregroundColor(selectedTrainer == nil ? .secondary : .primary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            TrainerPickerSheet(
                selectedTrainer: $selectedTrainer,
                trainers: trainers
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Trainer Picker Sheet
struct TrainerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTrainer: TrainerInfo?
    let trainers: [TrainerInfo]
    
    var body: some View {
        NavigationStack {
            List {
                // None option
                Button {
                    selectedTrainer = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("Không chọn")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedTrainer == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Trainer options
                ForEach(trainers) { trainer in
                    Button {
                        selectedTrainer = trainer
                        dismiss()
                    } label: {
                        HStack {
                            Text(trainer.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedTrainer?.id == trainer.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chọn Huấn luyện viên")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - User Picker Button
struct UserPickerButton: View {
    @Binding var selectedUsers: [UserInfo]
    let users: [UserInfo]
    let isLoading: Bool
    
    @State private var showPicker = false
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    
                    if selectedUsers.isEmpty {
                        Text("Chọn học viên")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(selectedUsers.count) học viên đã chọn")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Show selected users as chips
                if !selectedUsers.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(selectedUsers) { user in
                            SelectedUserChip(user: user) {
                                if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
                                    selectedUsers.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            UserPickerSheet(
                selectedUsers: $selectedUsers,
                users: users
            )
            .presentationDetents([.large])
        }
    }
}

// MARK: - Selected User Chip
struct SelectedUserChip: View {
    let user: UserInfo
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(user.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - User Picker Sheet
struct UserPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUsers: [UserInfo]
    let users: [UserInfo]
    
    @State private var searchText = ""
    
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { $0.matches(searchText: searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Tìm theo tên...", text: $searchText)
                        .font(.system(size: 16))
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Selected count
                if !selectedUsers.isEmpty {
                    HStack {
                        Text("Đã chọn: \(selectedUsers.count) học viên")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Bỏ chọn tất cả") {
                            selectedUsers.removeAll()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                
                List {
                    ForEach(filteredUsers) { user in
                        Button {
                            toggleUser(user)
                        } label: {
                            HStack {
                                // Avatar placeholder
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(user.name.prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .foregroundColor(.primary)
                                        .font(.system(size: 16))
                                    
                                    if let email = user.email {
                                        Text(email)
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 13))
                                    }
                                }
                                
                                Spacer()
                                
                                if isSelected(user) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 22))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Chọn học viên")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func isSelected(_ user: UserInfo) -> Bool {
        selectedUsers.contains(where: { $0.id == user.id })
    }
    
    private func toggleUser(_ user: UserInfo) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }
}

// MARK: - Flow Layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Time Picker Button
struct TimePickerButton: View {
    @Binding var time: Date
    let label: String
    
    @State private var showPicker = false
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "clock")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            TimePickerSheet(time: $time)
                .presentationDetents([.height(300)])
        }
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var time: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Chọn giờ",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Chọn giờ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Schedule Type Button
struct ScheduleTypeButton: View {
    let type: ScheduleType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(type.description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fixed Dates Picker Button
struct FixedDatesPickerButton: View {
    @Binding var selectedDates: [Date]
    let formattedText: String
    
    @State private var showPicker = false
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text(formattedText)
                    .font(.system(size: 16))
                    .foregroundColor(selectedDates.isEmpty ? .secondary : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            FixedDatesPickerSheet(selectedDates: $selectedDates)
        }
    }
}

// MARK: - Fixed Dates Picker Sheet
struct FixedDatesPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDates: [Date]
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month Navigation
                HStack {
                    Button {
                        previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text(currentMonthYear)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)
                
                // Weekday Header
                HStack(spacing: 0) {
                    ForEach(["CN", "T2", "T3", "T4", "T5", "T6", "T7"], id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(calendarDays.indices, id: \.self) { index in
                        if let date = calendarDays[index] {
                            FixedDateCell(
                                date: date,
                                isSelected: isDateSelected(date),
                                isToday: calendar.isDateInToday(date),
                                isPast: date < calendar.startOfDay(for: Date())
                            )
                            .onTapGesture {
                                toggleDate(date)
                            }
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Selected Dates Count
                if !selectedDates.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Đã chọn \(selectedDates.count) ngày")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Chọn ngày")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private var calendarDays: [Date?] {
        var days: [Date?] = []
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func toggleDate(_ date: Date) {
        // Don't allow past dates
        guard date >= calendar.startOfDay(for: Date()) else { return }
        
        if let index = selectedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(at: index)
        } else {
            selectedDates.append(date)
        }
        selectedDates.sort()
    }
}

// MARK: - Fixed Date Cell
struct FixedDateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isPast: Bool
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
            } else if isToday {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                .foregroundColor(
                    isPast ? .secondary.opacity(0.5) :
                    isSelected ? .white :
                    isToday ? .blue : .primary
                )
        }
        .frame(height: 44)
        .opacity(isPast ? 0.5 : 1)
    }
}

// MARK: - Fixed Date Chip
struct FixedDateChip: View {
    let date: Date
    let onRemove: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM (EEE)"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text(formattedDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.blue)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview {
    AddEventView()
}