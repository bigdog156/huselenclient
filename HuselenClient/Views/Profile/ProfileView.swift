//
//  ProfileView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var showWeightTracking = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showUploadSuccess = false
    
    private var userId: String {
        authViewModel.currentUser?.id.uuidString.lowercased() ?? ""
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Summary
                    statsSummary
                    
                    // Menu Items
                    menuSection
                    
                    // Sign Out Button
                    signOutButton
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hồ sơ")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert("Thành công", isPresented: $showUploadSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Ảnh đại diện đã được cập nhật")
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task {
                        let success = await viewModel.uploadAvatar(userId: userId, image: image)
                        if success {
                            showUploadSuccess = true
                        }
                        selectedImage = nil
                    }
                }
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadProfile(userId: userId.uuidString.lowercased())
                }
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with upload overlay
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let avatarUrl = viewModel.userProfile?.avatarUrl,
                       let url = URL(string: avatarUrl) {
                        CachedAvatarImage(
                            url: url,
                            size: 100,
                            placeholder: AnyView(defaultAvatar)
                        )
                    } else {
                        defaultAvatar
                            .frame(width: 100, height: 100)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                
                // Upload button
                Button {
                    showImagePicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: viewModel.isUploadingAvatar ? "arrow.clockwise" : "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(viewModel.isUploadingAvatar ? 360 : 0))
                            .animation(viewModel.isUploadingAvatar ? 
                                .linear(duration: 1).repeatForever(autoreverses: false) : .default, 
                                value: viewModel.isUploadingAvatar)
                    }
                }
                .disabled(viewModel.isUploadingAvatar)
                .offset(x: -5, y: -5)
            }
            
            // Name
            VStack(spacing: 4) {
                Text(viewModel.userProfile?.displayName ?? "Người dùng")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Edit Profile Button
            Button {
                // Navigate to edit profile
            } label: {
                Text("Chỉnh sửa hồ sơ")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 20)
    }
    
    private var defaultAvatar: some View {
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
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
    
    // MARK: - Stats Summary
    private var statsSummary: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(viewModel.totalCheckIns)", title: "Check-in")
            
            Divider()
                .frame(height: 40)
            
            StatItem(value: "\(viewModel.totalMealLogs)", title: "Bữa ăn")
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                value: viewModel.currentWeight != nil ? String(format: "%.1f", viewModel.currentWeight!) : "--",
                title: "Cân nặng (kg)"
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 2) {
            // Weight Tracking - Navigable
            Button {
                showWeightTracking = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Theo dõi cân nặng")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            ProfileMenuItem(icon: "target", title: "Mục tiêu của tôi", color: .orange)
            ProfileMenuItem(icon: "chart.line.uptrend.xyaxis", title: "Thống kê", color: .green)
            ProfileMenuItem(icon: "bell.fill", title: "Thông báo", color: .yellow)
            ProfileMenuItem(icon: "gearshape.fill", title: "Cài đặt", color: .gray)
            ProfileMenuItem(icon: "questionmark.circle.fill", title: "Trợ giúp", color: .purple)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .fullScreenCover(isPresented: $showWeightTracking) {
            WeightTrackingView(userId: userId)
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button {
            Task {
                await authViewModel.signOut()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Đăng xuất")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    ProfileView(authViewModel: AuthViewModel())
        .environmentObject(ProfileViewModel())
}

