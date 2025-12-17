//
//  CheckInViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Supabase

@MainActor
class CheckInViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var capturedImage: UIImage?
    @Published var isFlashOn = false
    @Published var isFrontCamera = true
    @Published var sessionNumber: Int = 1
    @Published var checkInSuccess = false
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Current Time
    var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    var currentDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: Date()).capitalized
    }
    
    // MARK: - Load Session Number
    func loadSessionNumber(userId: String) async {
        do {
            let response: [UserCheckIn] = try await supabase
                .from("user_check_ins")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            self.sessionNumber = response.count + 1
        } catch {
            self.sessionNumber = 1
        }
    }
    
    // MARK: - Toggle Flash
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    // MARK: - Toggle Camera
    func toggleCamera() {
        isFrontCamera.toggle()
    }
    
    // MARK: - Save Check-In
    func saveCheckIn(userId: String, workoutId: String?, image: UIImage?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            var photoUrl: String? = nil
            
            // Upload photo if exists
            if let image = image,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                let fileName = "\(userId)/checkin_\(Date().timeIntervalSince1970).jpg"
                
                try await supabase.storage
                    .from("checkins")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                photoUrl = try supabase.storage
                    .from("checkins")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }
            
            // Create check-in record
            let checkIn = UserCheckIn(
                userId: userId,
                sessionNumber: sessionNumber,
                photoUrl: photoUrl,
                checkInTime: Date(),
                note: nil,
                mood: nil
            )
            
            try await supabase
                .from("user_check_ins")
                .insert(checkIn)
                .execute()
            
            isLoading = false
            checkInSuccess = true
            return true
            
        } catch {
            isLoading = false
            errorMessage = "Không thể lưu check-in: \(error.localizedDescription)"
            return false
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var isFrontCamera = true
    @Published var isFlashOn = false
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }
        
        // Add camera input
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        if session.outputs.isEmpty {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func toggleCamera() {
        isFrontCamera.toggle()
        setupCamera()
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else { return }
        
        // Mirror the image if using front camera
        if isFrontCamera {
            if let cgImage = image.cgImage {
                image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
            }
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

