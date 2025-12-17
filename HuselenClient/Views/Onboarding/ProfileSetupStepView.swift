//
//  ProfileSetupStepView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI
import PhotosUI

struct ProfileSetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Avatar
                avatarSection
                    .frame(maxWidth: .infinity)
                
                // Display Name
                displayNameSection
                
                // Gender Selection
                genderSection
                
                // Goal Selection
                goalSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadImage()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chào mừng bạn!\nHãy bắt đầu nhé.")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            Text("Chúng mình cần một chút thông tin để cá nhân hóa lộ trình tập luyện của bạn.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar Circle
                if let image = viewModel.avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.75),
                                    Color(red: 1.0, green: 0.9, blue: 0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.8, blue: 0.7).opacity(0.5), lineWidth: 8)
                        )
                }
                
                // Camera Button
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }
        }
    }
    
    // MARK: - Display Name Section
    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tên hiển thị của bạn")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("Nhập tên của bạn", text: $viewModel.displayName)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Gender Section
    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Giới tính")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    GenderButton(
                        gender: gender,
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedGender = gender
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Goal Section
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mục tiêu chính của bạn là gì?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(FitnessGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.selectedGoal == goal
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedGoal = goal
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gender Button
struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(gender.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .blue : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    private var iconColor: Color {
        switch goal {
        case .loseFat: return .blue
        case .buildMuscle: return .gray
        case .health: return .pink
        case .reduceStress: return .indigo
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                Text(goal.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -12, y: 12)
                    }
                }
            )
        }
    }
}

#Preview {
    ProfileSetupStepView(viewModel: OnboardingViewModel())
}

