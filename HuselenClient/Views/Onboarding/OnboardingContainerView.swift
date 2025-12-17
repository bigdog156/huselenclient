//
//  OnboardingContainerView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressIndicator
                .padding(.top, 16)
                .padding(.bottom, 24)
            
            // Content
            TabView(selection: $viewModel.currentStep) {
                ProfileSetupStepView(viewModel: viewModel)
                    .tag(0)
                
                PhysicalInfoStepView(viewModel: viewModel)
                    .tag(1)
                
                ExperienceStepView(viewModel: viewModel)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)
            
            // Bottom Button
            bottomButton
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
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
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentStep ? Color.blue : Color(.systemGray4))
                    .frame(width: index == viewModel.currentStep ? 32 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
    }
    
    // MARK: - Bottom Button
    private var bottomButton: some View {
        HStack(spacing: 16) {
            // Back button (only show if not on first step)
            if viewModel.currentStep > 0 {
                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            
            // Continue/Finish button
            Button {
                if viewModel.currentStep == viewModel.totalSteps - 1 {
                    // Final step - save and complete
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            // Use lowercase UUID to match PostgreSQL format
                            let userIdString = userId.uuidString.lowercased()
                            let success = await viewModel.saveProfile(userId: userIdString)
                            if success {
                                // Complete onboarding in AuthViewModel
                                authViewModel.completeOnboarding()
                                showOnboarding = false
                            }
                        }
                    }
                } else {
                    viewModel.nextStep()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.currentStep == viewModel.totalSteps - 1 ? "Hoàn thành" : "Tiếp tục")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Image(systemName: viewModel.currentStep == viewModel.totalSteps - 1 ? "checkmark" : "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.canProceedFromCurrentStep ? Color.blue : Color.blue.opacity(0.5))
                )
            }
            .disabled(!viewModel.canProceedFromCurrentStep || viewModel.isLoading)
        }
    }
}

#Preview {
    OnboardingContainerView(authViewModel: AuthViewModel(), showOnboarding: .constant(true))
}

