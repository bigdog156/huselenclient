//
//  ProfileViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import Supabase
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUploadingAvatar = false
    
    // Real stats from database
    @Published var totalCheckIns = 0
    @Published var totalMealLogs = 0
    @Published var totalWeightLogs = 0
    @Published var currentWeight: Double?
    @Published var latestWeightChange: Double?
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Load Profile
    func loadProfile(userId: String) async {
        isLoading = true
        
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
            
            // Load real stats
            await loadUserStats(userId: userId)
        } catch {
            print("Error loading profile: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Load User Stats
    private func loadUserStats(userId: String) async {
        // Load check-in count
        await loadCheckInStats(userId: userId)
        
        // Load meal log count
        await loadMealLogStats(userId: userId)
        
        // Load weight stats
        await loadWeightStats(userId: userId)
    }
    
    // MARK: - Load Check-In Stats
    private func loadCheckInStats(userId: String) async {
        do {
            let checkIns: [CheckInCountResponse] = try await supabase
                .from("user_check_ins")
                .select("id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            self.totalCheckIns = checkIns.count
        } catch {
            print("Error loading check-in stats: \(error)")
        }
    }
    
    // MARK: - Load Meal Log Stats
    private func loadMealLogStats(userId: String) async {
        do {
            let mealLogs: [MealLogCountResponse] = try await supabase
                .from("user_meal_logs")
                .select("id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            self.totalMealLogs = mealLogs.count
        } catch {
            print("Error loading meal log stats: \(error)")
        }
    }
    
    // MARK: - Load Weight Stats
    private func loadWeightStats(userId: String) async {
        do {
            let weightLogs: [WeightLogStatsResponse] = try await supabase
                .from("user_weight_logs")
                .select("id, weight_kg, logged_date")
                .eq("user_id", value: userId)
                .order("logged_date", ascending: false)
                .execute()
                .value
            
            self.totalWeightLogs = weightLogs.count
            
            if let latest = weightLogs.first {
                self.currentWeight = latest.weightKg
                
                // Calculate weight change if there are at least 2 logs
                if weightLogs.count >= 2 {
                    self.latestWeightChange = latest.weightKg - weightLogs[1].weightKg
                }
            }
        } catch {
            print("Error loading weight stats: \(error)")
        }
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(userId: String, image: UIImage) async -> Bool {
        isUploadingAvatar = true
        errorMessage = nil
        
        do {
            // Compress image
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                errorMessage = "Không thể nén ảnh"
                isUploadingAvatar = false
                return false
            }
            
            // Generate unique filename
            let fileName = "\(userId)_\(UUID().uuidString).jpg"
            let filePath = "avatars/\(fileName)"
            
            // Upload to Supabase Storage
            let data = Data(imageData)
            try await supabase.storage
                .from("user-avatars")
                .upload(
                    path: filePath,
                    file: data,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            // Get public URL
            let publicURL = try supabase.storage
                .from("user-avatars")
                .getPublicURL(path: filePath)
            
            // Update profile with new avatar URL
            try await supabase
                .from("profiles")
                .update(["avatar_url": publicURL.absoluteString])
                .eq("user_id", value: userId)
                .execute()
            
            // Reload profile to get updated data
            await loadProfile(userId: userId)
            
            isUploadingAvatar = false
            return true
        } catch {
            print("Error uploading avatar: \(error)")
            errorMessage = "Lỗi tải ảnh lên: \(error.localizedDescription)"
            isUploadingAvatar = false
            return false
        }
    }
}

// MARK: - Response Models
private struct CheckInCountResponse: Codable {
    let id: String
}

private struct MealLogCountResponse: Codable {
    let id: String
}

private struct WeightLogStatsResponse: Codable {
    let id: String
    let weightKg: Double
    let loggedDate: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case weightKg = "weight_kg"
        case loggedDate = "logged_date"
    }
}

