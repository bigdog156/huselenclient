//
//  WeightTrackingViewModel.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class WeightTrackingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weightLogs: [UserWeightLog] = []
    @Published var chartData: [WeightChartPoint] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    
    // Input state
    @Published var inputWeight: String = ""
    @Published var capturedPhoto: UIImage?
    
    // Week limit tracking
    @Published var logsThisWeek: Int = 0
    @Published var canLogMoreThisWeek: Bool = true
    
    private let supabase = SupabaseConfig.client
    private let maxLogsPerWeek = 2
    
    // MARK: - Computed Properties
    var latestWeight: Double? {
        weightLogs.first?.weightKg
    }
    
    var weightChange: Double? {
        guard weightLogs.count >= 2 else { return nil }
        return weightLogs[0].weightKg - weightLogs[1].weightKg
    }
    
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date()).capitalized
    }
    
    var remainingLogsThisWeek: Int {
        max(0, maxLogsPerWeek - logsThisWeek)
    }
    
    // MARK: - Load Weight Logs
    func loadWeightLogs(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all weight logs, ordered by date descending
            let response: [UserWeightLog] = try await supabase
                .from("user_weight_logs")
                .select()
                .eq("user_id", value: userId)
                .order("logged_date", ascending: false)
                .execute()
                .value
            
            self.weightLogs = response
            self.updateChartData()
            await self.checkWeeklyLimit(userId: userId)
            
        } catch {
            self.errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Check Weekly Limit
    func checkWeeklyLimit(userId: String) async {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else { return }
        
        // Get end of week (Sunday)
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return }
        
        let startString = DateFormatters.dateOnly.string(from: startOfWeek)
        let endString = DateFormatters.dateOnly.string(from: endOfWeek)
        
        do {
            let response: [UserWeightLog] = try await supabase
                .from("user_weight_logs")
                .select()
                .eq("user_id", value: userId)
                .gte("logged_date", value: startString)
                .lte("logged_date", value: endString)
                .execute()
                .value
            
            self.logsThisWeek = response.count
            self.canLogMoreThisWeek = response.count < maxLogsPerWeek
            
        } catch {
            // If error, assume can log
            self.logsThisWeek = 0
            self.canLogMoreThisWeek = true
        }
    }
    
    // MARK: - Save Weight Log
    func saveWeightLog(userId: String, weight: Double, photo: UIImage?) async -> Bool {
        guard canLogMoreThisWeek else {
            errorMessage = "Bạn đã đạt giới hạn 2 lần/tuần"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        
        do {
            var photoUrl: String? = nil
            
            // Upload photo if exists
            if let photo = photo,
               let imageData = photo.jpegData(compressionQuality: 0.7) {
                let fileName = "\(userId)/weight_\(Date().timeIntervalSince1970).jpg"
                
                try await supabase.storage
                    .from("weight-photos")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                photoUrl = try supabase.storage
                    .from("weight-photos")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }
            
            // Create weight log
            let weightLog = UserWeightLog(
                userId: userId,
                weightKg: weight,
                photoUrl: photoUrl,
                inputType: photo != nil ? .photo : .manual,
                loggedDate: Date()
            )
            
            try await supabase
                .from("user_weight_logs")
                .insert(weightLog)
                .execute()
            
            // Reload data
            await loadWeightLogs(userId: userId)
            
            // Reset input
            inputWeight = ""
            capturedPhoto = nil
            saveSuccess = true
            isSaving = false
            
            return true
            
        } catch {
            isSaving = false
            errorMessage = "Không thể lưu: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Update Chart Data
    private func updateChartData() {
        // Get logs for current month only
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let monthLogs = weightLogs.filter { log in
            let logMonth = calendar.component(.month, from: log.loggedDate)
            let logYear = calendar.component(.year, from: log.loggedDate)
            return logMonth == currentMonth && logYear == currentYear
        }
        
        // Convert to chart points and sort by date ascending
        chartData = monthLogs
            .map { WeightChartPoint(date: $0.loggedDate, weight: $0.weightKg) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Validate Input
    func validateWeight(_ input: String) -> Double? {
        let cleanedInput = input.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(cleanedInput),
              weight > 20 && weight < 300 else {
            return nil
        }
        return weight
    }
    
    // MARK: - Reset State
    func resetInput() {
        inputWeight = ""
        capturedPhoto = nil
        errorMessage = nil
        saveSuccess = false
    }
}

