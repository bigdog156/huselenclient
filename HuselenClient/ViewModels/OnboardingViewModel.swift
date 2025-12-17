//
//  OnboardingViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import SwiftUI
import PhotosUI
import Supabase

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Step 1: Profile
    @Published var displayName = ""
    @Published var selectedGender: Gender?
    @Published var selectedGoal: FitnessGoal?
    @Published var avatarImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    // Step 2: Physical Info
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var birthDate = Date()
    
    // Step 3: Experience
    @Published var experienceLevel: ExperienceLevel?
    
    let totalSteps = 3
    private let supabase = SupabaseConfig.client
    
    // MARK: - Computed Properties
    var canProceedFromStep1: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedGender != nil &&
        selectedGoal != nil
    }
    
    var canProceedFromStep2: Bool {
        !height.isEmpty && !weight.isEmpty
    }
    
    var canProceedFromStep3: Bool {
        experienceLevel != nil
    }
    
    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 0: return canProceedFromStep1
        case 1: return canProceedFromStep2
        case 2: return canProceedFromStep3
        default: return false
        }
    }
    
    // MARK: - Navigation
    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    // MARK: - Photo Handling
    func loadImage() async {
        guard let item = selectedPhotoItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
    
    // MARK: - Save Profile
    func saveProfile(userId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            var avatarUrl: String? = nil
            
            // Upload avatar if exists
            if let image = avatarImage,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                let fileName = "\(userId)/avatar.jpg"
                
                try await supabase.storage
                    .from("avatars")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                avatarUrl = try supabase.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }
            
            // Create profile
            let profile = UserProfile(
                userId: userId,
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                avatarUrl: avatarUrl,
                gender: selectedGender,
                fitnessGoal: selectedGoal,
                experienceLevel: experienceLevel,
                height: Double(height),
                weight: Double(weight),
                birthDate: birthDate,
                onboardingCompleted: true
            )
            
            try await supabase
                .from("profiles")
                .upsert(profile)
                .execute()
            
            isLoading = false
            return true
            
        } catch {
            isLoading = false
            errorMessage = "Không thể lưu thông tin: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Check Onboarding Status
    func checkOnboardingStatus(userId: String) async -> Bool {
        do {
            let response: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            return response.onboardingCompleted
        } catch {
            return false
        }
    }
}

