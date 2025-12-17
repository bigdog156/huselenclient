//
//  ExperienceStepView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ExperienceStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Illustration
                illustrationSection
                    .frame(maxWidth: .infinity)
                
                // Experience Options
                experienceOptionsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kinh nghiệm tập luyện")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Bạn đã tập luyện được bao lâu rồi?")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Illustration Section
    private var illustrationSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.15),
                            Color.yellow.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .yellow]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Experience Options Section
    private var experienceOptionsSection: some View {
        VStack(spacing: 12) {
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                ExperienceLevelCard(
                    level: level,
                    isSelected: viewModel.experienceLevel == level
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.experienceLevel = level
                    }
                }
            }
        }
    }
}

// MARK: - Experience Level Card
struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let action: () -> Void
    
    private var iconColor: Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: level.icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(level.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    ExperienceStepView(viewModel: OnboardingViewModel())
}

