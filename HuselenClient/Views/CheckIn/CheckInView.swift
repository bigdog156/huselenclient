//
//  CheckInView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI
import AVFoundation

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CheckInViewModel()
    @StateObject private var cameraManager = CameraManager()
    
    let userId: String
    let workoutId: String?
    var onCheckInComplete: (() -> Void)?
    
    @State private var showSuccessView = false
    @State private var showPreview = false
    @State private var finalImage: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - Camera or Preview with Overlay
                if showPreview, let image = cameraManager.capturedImage {
                    // Show captured image with overlay
                    CheckInPreviewContent(
                        image: image,
                        sessionNumber: viewModel.sessionNumber,
                        currentTime: viewModel.currentTime,
                        currentDate: viewModel.currentDate,
                        screenSize: geometry.size
                    )
                    .ignoresSafeArea()
                } else {
                    // Camera Preview with live overlay
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                            .ignoresSafeArea()
                        
                        // Live overlay on camera
                        CheckInOverlay(
                            sessionNumber: viewModel.sessionNumber,
                            currentTime: viewModel.currentTime,
                            currentDate: viewModel.currentDate,
                            showMotivationalText: true
                        )
                    }
                }
                
                // Content Overlay (top bar and controls)
                VStack {
                    // Top Bar
                    topBar
                    
                    Spacer()
                    
                    // Bottom Controls
                    if showPreview {
                        previewControls
                    } else {
                        cameraControls
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Success Overlay
                if showSuccessView {
                    successOverlay
                }
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.loadSessionNumber(userId: userId)
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if newImage != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPreview = true
                }
            }
        }
        .onChange(of: viewModel.checkInSuccess) { _, success in
            if success {
                withAnimation(.easeInOut) {
                    showSuccessView = true
                }
                
                // Auto dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onCheckInComplete?()
                    dismiss()
                }
            }
        }
        .alert("Lỗi", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Close/Back Button
            Button {
                if showPreview {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPreview = false
                        cameraManager.capturedImage = nil
                        finalImage = nil
                    }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: showPreview ? "chevron.left" : "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            Spacer()
            
            // Flash Button (only show in camera mode)
            if !showPreview {
                Button {
                    cameraManager.toggleFlash()
                } label: {
                    Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
            }
        }
    }
    
    // MARK: - Camera Controls
    private var cameraControls: some View {
        HStack(alignment: .center, spacing: 0) {
            // Gallery placeholder
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text("No upload")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            
            // Capture Button
            Button {
                cameraManager.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Flip Camera
            Button {
                cameraManager.toggleCamera()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Preview Controls
    private var previewControls: some View {
        HStack(spacing: 16) {
            // Retake Button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPreview = false
                    cameraManager.capturedImage = nil
                    finalImage = nil
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Chụp lại")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                )
            }
            
            // Confirm Button
            Button {
                Task {
                    // Create image with overlay
                    if let originalImage = cameraManager.capturedImage {
                        let imageWithOverlay = createImageWithOverlay(
                            originalImage: originalImage,
                            sessionNumber: viewModel.sessionNumber,
                            currentTime: viewModel.currentTime,
                            currentDate: viewModel.currentDate
                        )
                        
                        await viewModel.saveCheckIn(
                            userId: userId,
                            workoutId: workoutId,
                            image: imageWithOverlay
                        )
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Xác nhận")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                )
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Captured Image Thumbnail with overlay
                if let image = cameraManager.capturedImage {
                    let finalImg = createImageWithOverlay(
                        originalImage: image,
                        sessionNumber: viewModel.sessionNumber,
                        currentTime: viewModel.currentTime,
                        currentDate: viewModel.currentDate
                    )
                    
                    Image(uiImage: finalImg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green, lineWidth: 3)
                        )
                        .overlay(
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 60, y: -85)
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Check-in thành công!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Buổi tập #\(viewModel.sessionNumber)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Ảnh đã được lưu")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Create Image with Overlay
    private func createImageWithOverlay(
        originalImage: UIImage,
        sessionNumber: Int,
        currentTime: String,
        currentDate: String
    ) -> UIImage {
        let imageSize = originalImage.size
        let scale = originalImage.scale
        
        // Use scale 1.0 to avoid double-scaling issues
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        
        // Draw original image
        originalImage.draw(in: CGRect(origin: .zero, size: imageSize))
        
        // Get context
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return originalImage
        }
        
        // Calculate base scale factor relative to a reference height (like iPhone screen ~800pt)
        // This ensures consistent overlay sizing regardless of image resolution
        let referenceHeight: CGFloat = 800
        let scaleFactor = imageSize.height / referenceHeight
        
        // Draw gradient overlay at bottom (same ratio as SwiftUI: 450/screenHeight)
        let gradientHeight: CGFloat = 450 * scaleFactor
        let gradientRect = CGRect(
            x: 0,
            y: imageSize.height - gradientHeight,
            width: imageSize.width,
            height: gradientHeight
        )
        
        let colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: gradientRect.midX, y: gradientRect.minY),
                end: CGPoint(x: gradientRect.midX, y: gradientRect.maxY),
                options: []
            )
        }
        
        // Calculate positions to match SwiftUI overlay
        // SwiftUI uses .padding(.bottom, 180) from bottom
        let centerX = imageSize.width / 2
        let bottomPadding: CGFloat = 180 * scaleFactor
        let contentBottomY = imageSize.height - bottomPadding
        
        // Font sizes scaled proportionally
        let timeFontSize: CGFloat = 72 * scaleFactor
        let dateFontSize: CGFloat = 20 * scaleFactor
        let badgeFontSize: CGFloat = 14 * scaleFactor
        
        // Spacing between elements (matching SwiftUI VStack spacing: 16)
        let spacing: CGFloat = 16 * scaleFactor
        
        // Draw date (bottom element)
        let dateFont = UIFont.systemFont(ofSize: dateFontSize, weight: .medium)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.white
        ]
        let dateSize = (currentDate as NSString).size(withAttributes: dateAttributes)
        let dateY = contentBottomY - dateSize.height
        let dateRect = CGRect(
            x: centerX - dateSize.width / 2,
            y: dateY,
            width: dateSize.width,
            height: dateSize.height
        )
        (currentDate as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        
        // Draw time (above date)
        let timeFont = UIFont.systemFont(ofSize: timeFontSize, weight: .bold)
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: timeFont,
            .foregroundColor: UIColor.white
        ]
        let timeSize = (currentTime as NSString).size(withAttributes: timeAttributes)
        let timeY = dateY - spacing - timeSize.height
        let timeRect = CGRect(
            x: centerX - timeSize.width / 2,
            y: timeY,
            width: timeSize.width,
            height: timeSize.height
        )
        (currentTime as NSString).draw(in: timeRect, withAttributes: timeAttributes)
        
        // Draw session badge (above time)
        let badgeText = "🏋️ BUỔI TẬP #\(sessionNumber)"
        let badgeFont = UIFont.systemFont(ofSize: badgeFontSize, weight: .bold)
        let badgeAttributes: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: UIColor.white
        ]
        let badgeTextSize = (badgeText as NSString).size(withAttributes: badgeAttributes)
        
        // Badge padding (matching SwiftUI: horizontal 16, vertical 10)
        let badgePaddingH: CGFloat = 16 * scaleFactor
        let badgePaddingV: CGFloat = 10 * scaleFactor
        
        let badgeWidth = badgeTextSize.width + badgePaddingH * 2
        let badgeHeight = badgeTextSize.height + badgePaddingV * 2
        let badgeY = timeY - spacing - badgeHeight
        
        let badgeRect = CGRect(
            x: centerX - badgeWidth / 2,
            y: badgeY,
            width: badgeWidth,
            height: badgeHeight
        )
        
        // Badge background (capsule shape)
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeHeight / 2)
        UIColor.white.withAlphaComponent(0.2).setFill()
        badgePath.fill()
        
        // Badge border
        UIColor.white.withAlphaComponent(0.3).setStroke()
        badgePath.lineWidth = 1 * scaleFactor
        badgePath.stroke()
        
        // Badge text (centered in badge)
        let badgeTextRect = CGRect(
            x: centerX - badgeTextSize.width / 2,
            y: badgeY + badgePaddingV,
            width: badgeTextSize.width,
            height: badgeTextSize.height
        )
        (badgeText as NSString).draw(in: badgeTextRect, withAttributes: badgeAttributes)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? originalImage
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}

// MARK: - Check-In Preview Content (shows image with overlay)
struct CheckInPreviewContent: View {
    let image: UIImage
    let sessionNumber: Int
    let currentTime: String
    let currentDate: String
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            // Background image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: screenSize.width, height: screenSize.height)
                .clipped()
            
            // Overlay
            CheckInOverlay(
                sessionNumber: sessionNumber,
                currentTime: currentTime,
                currentDate: currentDate,
                showMotivationalText: false
            )
        }
    }
}

// MARK: - Check-In Overlay
struct CheckInOverlay: View {
    let sessionNumber: Int
    let currentTime: String
    let currentDate: String
    let showMotivationalText: Bool
    
    var body: some View {
        ZStack {
            // Gradient overlay
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 450)
            }
            
            // Content
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Session Badge
                    HStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 14))
                        
                        Text("BUỔI TẬP #\(sessionNumber)")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Time
                    Text(currentTime)
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Date
                    Text(currentDate)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Motivational Text
                    if showMotivationalText {
                        Text("Hãy ghi lại khoảnh khắc chân thật\nngay lúc này")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 180)
            }
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.session = session
    }
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            
            DispatchQueue.main.async {
                if self.previewLayer == nil {
                    let layer = AVCaptureVideoPreviewLayer(session: session)
                    layer.videoGravity = .resizeAspectFill
                    layer.frame = self.bounds
                    self.layer.addSublayer(layer)
                    self.previewLayer = layer
                } else {
                    self.previewLayer?.session = session
                }
            }
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

#Preview {
    CheckInView(userId: "test", workoutId: nil)
}
