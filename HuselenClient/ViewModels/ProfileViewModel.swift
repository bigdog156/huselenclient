//
//  ProfileViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock stats for now
    @Published var totalWorkouts = 24
    @Published var totalMinutes = 1080
    @Published var totalCalories = 12500
    
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
        } catch {
            print("Error loading profile: \(error)")
        }
        
        isLoading = false
    }
}

