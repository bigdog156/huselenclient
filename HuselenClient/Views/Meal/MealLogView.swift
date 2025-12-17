//
//  MealLogView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI
import AVFoundation

struct MealLogView: View {
    @StateObject private var viewModel = MealLogViewModel()
    @State private var showCamera = false
    @State private var showDatePicker = false
    @State private var captureForMealType: MealType?
    
    let userId: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week Calendar
                weekCalendarView
                
                Divider()
                
                // Meal List
                ScrollView {
                    VStack(spacing: 24) {
                        // Main meals (Sáng, Trưa, Chiều)
                        ForEach([MealType.breakfast, .lunch, .afternoon], id: \.self) { mealType in
                            MealSectionView(
                                mealType: mealType,
                                mealLog: viewModel.mealLogs[mealType],
                                onTapPhoto: {
                                    captureForMealType = mealType
                                    showCamera = true
                                },
                                onSaveNote: { note in
                                    Task {
                                        await viewModel.saveMealLog(
                                            userId: userId,
                                            mealType: mealType,
                                            photo: nil,
                                            note: note,
                                            feeling: nil
                                        )
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteMealLog(userId: userId, mealType: mealType)
                                    }
                                }
                            )
                        }
                        
                        // Dinner (Optional) - Collapsible
                        DinnerSectionView(
                            mealLog: viewModel.mealLogs[.dinner],
                            onTapPhoto: {
                                captureForMealType = .dinner
                                showCamera = true
                            },
                            onSaveNote: { note in
                                Task {
                                    await viewModel.saveMealLog(
                                        userId: userId,
                                        mealType: .dinner,
                                        photo: nil,
                                        note: note,
                                        feeling: nil
                                    )
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteMealLog(userId: userId, mealType: .dinner)
                                }
                            }
                        )
                        
                        // Motivational quote
                        Text("\"Eat to nourish, not to punish.\"")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nhật ký ăn uống")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                viewModel.initializeWeekDates()
                await viewModel.loadMeals(userId: userId)
            }
            .sheet(isPresented: $showCamera) {
                if let mealType = captureForMealType {
                    MealPhotoCapture(
                        mealType: mealType,
                        isPresented: $showCamera,
                        onCapture: { image in
                            Task {
                                await viewModel.saveMealLog(
                                    userId: userId,
                                    mealType: mealType,
                                    photo: image,
                                    note: nil,
                                    feeling: nil
                                )
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(
                    selectedDate: viewModel.selectedDate,
                    onSelect: { date in
                        Task {
                            await viewModel.selectDate(date, userId: userId)
                        }
                        showDatePicker = false
                    },
                    onDismiss: {
                        showDatePicker = false
                    }
                )
            }
            .alert("Lỗi", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Week Calendar View
    private var weekCalendarView: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekDates, id: \.self) { date in
                Button {
                    Task {
                        await viewModel.selectDate(date, userId: userId)
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(viewModel.dayName(for: date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(
                                viewModel.isSelected(date) ? .blue :
                                    viewModel.isDateToday(date) ? .blue : .secondary
                            )
                        
                        ZStack {
                            if viewModel.isSelected(date) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 36, height: 36)
                            }
                            
                            Text(viewModel.dayNumber(for: date))
                                .font(.system(size: 16, weight: viewModel.isSelected(date) ? .bold : .regular))
                                .foregroundColor(
                                    viewModel.isSelected(date) ? .white :
                                        viewModel.isDateToday(date) ? .blue : .primary
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Meal Section View
struct MealSectionView: View {
    let mealType: MealType
    let mealLog: UserMealLog?
    let onTapPhoto: () -> Void
    let onSaveNote: (String) -> Void
    let onDelete: () -> Void
    
    @State private var noteText: String = ""
    @State private var showMenu = false
    @FocusState private var isNoteFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(mealType.displayName)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                if let log = mealLog, log.hasContent {
                    Text(log.formattedTime)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    Text(mealType.placeholder)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Content - Locket Style 1:1 Photo
            if let log = mealLog, let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                // Photo Card - Locket Style
                LocketStylePhotoCard(
                    url: url,
                    note: log.note,
                    onDelete: onDelete
                )
            } else {
                // Empty state - Photo capture area (1:1 ratio)
                Button {
                    onTapPhoto()
                } label: {
                    GeometryReader { geometry in
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.secondary)
                                
                                // Plus badge
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 20, y: -20)
                            }
                            
                            Text(mealType.photoPlaceholder)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.width) // 1:1 ratio
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                .foregroundColor(Color(.systemGray4))
                        )
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            
            // Note Input
            HStack(spacing: 12) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                TextField("Ghi chú ngắn...", text: $noteText)
                    .font(.system(size: 15))
                    .focused($isNoteFocused)
                    .onSubmit {
                        if !noteText.isEmpty {
                            onSaveNote(noteText)
                            noteText = ""
                        }
                    }
                
                if !noteText.isEmpty {
                    Button {
                        onSaveNote(noteText)
                        noteText = ""
                        isNoteFocused = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            
            // Feeling selector (only show if meal has content)
            if mealLog?.hasContent == true {
                feelingSelector
            }
        }
        .onAppear {
            noteText = mealLog?.note ?? ""
        }
    }
    
    // MARK: - Feeling Selector
    private var feelingSelector: some View {
        HStack(spacing: 16) {
            Text("CẢM NHẬN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)
            
            Spacer()
            
            ForEach(MealFeeling.allCases, id: \.self) { feeling in
                Button {
                    // Handle feeling selection
                } label: {
                    Image(systemName: feeling.icon)
                        .font(.system(size: 20))
                        .foregroundColor(mealLog?.feeling == feeling ? feeling.color : .secondary.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Locket Style Photo Card
struct LocketStylePhotoCard: View {
    let url: URL
    let note: String?
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo with 1:1 aspect ratio
            GeometryReader { geometry in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                // Locket style shadow
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Menu button - Locket style
            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Xóa", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
            }
            .padding(16)
        }
        
        // Note below photo if exists
        if let note = note, !note.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Dinner Section View (Collapsible)
struct DinnerSectionView: View {
    let mealLog: UserMealLog?
    let onTapPhoto: () -> Void
    let onSaveNote: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(MealType.dinner.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("TÙY CHỌN")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            // Content (when expanded or has content)
            if isExpanded || mealLog?.hasContent == true {
                if let log = mealLog, let photoUrl = log.photoUrl, let url = URL(string: photoUrl) {
                    // Photo Card - Locket Style 1:1
                    LocketStylePhotoCard(
                        url: url,
                        note: log.note,
                        onDelete: onDelete
                    )
                } else if isExpanded {
                    // Photo capture button - 1:1 style
                    Button {
                        onTapPhoto()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 18, y: -18)
                            }
                            
                            TextField("Bạn đã ăn gì?", text: $noteText)
                                .font(.system(size: 15))
                                .focused($isNoteFocused)
                            
                            if !noteText.isEmpty {
                                Button {
                                    onSaveNote(noteText)
                                    noteText = ""
                                    isNoteFocused = false
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Meal Photo Capture (Locket Style)
struct MealPhotoCapture: View {
    let mealType: MealType
    @Binding var isPresented: Bool
    let onCapture: (UIImage) -> Void
    
    @StateObject private var cameraManager = MealCameraManager()
    @State private var capturedImage: UIImage?
    @State private var showPreview = false
    @State private var cameraReady = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showPreview, let image = capturedImage {
                // Preview captured image
                previewView(image: image)
            } else {
                // Camera capture view
                cameraView
            }
        }
        .onAppear {
            // Ensure camera starts when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cameraManager.startSession()
                cameraReady = true
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Camera View
    private var cameraView: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let squareSize = screenWidth - 40
            let squareY = (screenHeight - squareSize) / 2
            
            ZStack(alignment: .top) {
                // Full screen camera preview
                MealCameraPreview(session: cameraManager.session)
                    .frame(width: screenWidth, height: screenHeight)
                
                // Dark overlay - Top
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: screenWidth, height: squareY)
                
                // Dark overlay - Left
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 20, height: squareSize)
                    .position(x: 10, y: squareY + squareSize / 2)
                
                // Dark overlay - Right
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 20, height: squareSize)
                    .position(x: screenWidth - 10, y: squareY + squareSize / 2)
                
                // Dark overlay - Bottom
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: screenWidth, height: screenHeight - squareY - squareSize)
                    .position(x: screenWidth / 2, y: squareY + squareSize + (screenHeight - squareY - squareSize) / 2)
                
                // Viewfinder border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: squareSize, height: squareSize)
                    .position(x: screenWidth / 2, y: squareY + squareSize / 2)
                
                // UI Overlay
                VStack {
                    // Top bar
                    HStack {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                )
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text(mealType.displayName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Flash toggle
                        Button {
                            cameraManager.toggleFlash()
                        } label: {
                            Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Capture button
                    Button {
                        cameraManager.capturePhoto { image in
                            if let image = image {
                                // First normalize orientation, then crop
                                let normalizedImage = normalizeImageOrientation(image)
                                let croppedImage = cropToSquare(
                                    image: normalizedImage,
                                    viewfinderSize: squareSize,
                                    screenSize: geometry.size
                                )
                                capturedImage = croppedImage
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPreview = true
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 85, height: 85)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 75, height: 75)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .disabled(!cameraReady)
                    .padding(.bottom, 50)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Preview View
    private func previewView(image: UIImage) -> some View {
        GeometryReader { geometry in
            let squareSize = geometry.size.width - 40
            
            VStack {
                // Top bar
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPreview = false
                            capturedImage = nil
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Chụp lại")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                        )
                    }
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Preview image - Locket style
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: squareSize, height: squareSize)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Spacer()
                
                // Confirm button
                Button {
                    onCapture(image)
                    isPresented = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Sử dụng ảnh này")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Normalize Image Orientation
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    // MARK: - Crop to Square
    private func cropToSquare(image: UIImage, viewfinderSize: CGFloat, screenSize: CGSize) -> UIImage {
        let imageSize = image.size
        
        // Camera uses aspectFill - image fills the screen
        // Calculate which dimension is the constraint
        let screenAspect = screenSize.width / screenSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        var displayedWidth: CGFloat
        var displayedHeight: CGFloat
        var imageOffsetX: CGFloat = 0
        var imageOffsetY: CGFloat = 0
        
        if imageAspect > screenAspect {
            // Image is wider - height fills screen
            displayedHeight = imageSize.height
            displayedWidth = screenSize.width * (imageSize.height / screenSize.height)
            imageOffsetX = (imageSize.width - displayedWidth) / 2
        } else {
            // Image is taller - width fills screen
            displayedWidth = imageSize.width
            displayedHeight = screenSize.height * (imageSize.width / screenSize.width)
            imageOffsetY = (imageSize.height - displayedHeight) / 2
        }
        
        // Scale from screen to image coordinates
        let scaleX = displayedWidth / screenSize.width
        let scaleY = displayedHeight / screenSize.height
        
        // Viewfinder center position on screen
        let viewfinderCenterX = screenSize.width / 2
        let viewfinderCenterY = screenSize.height / 2
        
        // Convert to image coordinates
        let imageCropCenterX = imageOffsetX + (viewfinderCenterX * scaleX)
        let imageCropCenterY = imageOffsetY + (viewfinderCenterY * scaleY)
        let imageCropSize = viewfinderSize * scaleX
        
        // Calculate crop rect
        var cropX = imageCropCenterX - (imageCropSize / 2)
        var cropY = imageCropCenterY - (imageCropSize / 2)
        var cropSize = imageCropSize
        
        // Clamp to image bounds
        cropX = max(0, min(cropX, imageSize.width - cropSize))
        cropY = max(0, min(cropY, imageSize.height - cropSize))
        cropSize = min(cropSize, min(imageSize.width - cropX, imageSize.height - cropY))
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)
        
        // Perform crop
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            // Fallback: simple center crop
            return simpleCenterCrop(image: image)
        }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Simple Center Crop (Fallback)
    private func simpleCenterCrop(image: UIImage) -> UIImage {
        let size = image.size
        let minDimension = min(size.width, size.height)
        
        let cropRect = CGRect(
            x: (size.width - minDimension) / 2,
            y: (size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    let selectedDate: Date
    let onSelect: (Date) -> Void
    let onDismiss: () -> Void
    
    @State private var tempDate: Date
    
    init(selectedDate: Date, onSelect: @escaping (Date) -> Void, onDismiss: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        self.onDismiss = onDismiss
        self._tempDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Chọn ngày",
                    selection: $tempDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Chọn ngày")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chọn") {
                        onSelect(tempDate)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Meal Camera Manager
class MealCameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isFlashOn = false
    @Published var isSessionRunning = false
    
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var currentDevice: AVCaptureDevice?
    private var isConfigured = false
    
    override init() {
        super.init()
        checkPermissionAndSetup()
    }
    
    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    func setupCamera() {
        guard !isConfigured else { return }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Remove existing outputs
        session.outputs.forEach { session.removeOutput($0) }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        isConfigured = true
    }
    
    func startSession() {
        guard isConfigured, !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.session.isRunning ?? false
            }
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard session.isRunning else {
            completion(nil)
            return
        }
        
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        
        // Set flash mode
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}

extension MealCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.captureCompletion?(image)
        }
    }
}

// MARK: - Meal Camera Preview
struct MealCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> MealCameraPreviewUIView {
        let view = MealCameraPreviewUIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        return view
    }
    
    func updateUIView(_ uiView: MealCameraPreviewUIView, context: Context) {
        uiView.setSession(session)
    }
    
    static func dismantleUIView(_ uiView: MealCameraPreviewUIView, coordinator: ()) {
        // Cleanup if needed
    }
}

class MealCameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setSession(_ session: AVCaptureSession) {
        // Remove existing layer if any
        previewLayer?.removeFromSuperlayer()
        
        // Create new preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

#Preview {
    MealLogView(userId: "test-user-id")
}

