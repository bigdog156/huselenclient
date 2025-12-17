//
//  SignUpView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreeToTerms = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image
                    headerImage
                    
                    // Content
                    VStack(spacing: 24) {
                        // Title
                        titleSection
                        
                        // Form Fields
                        formFields
                        
                        // Terms Checkbox
                        termsCheckbox
                        
                        // Sign Up Button
                        signUpButton
                        
                        // Divider
                        dividerSection
                        
                        // Social Login Buttons
                        socialLoginButtons
                        
                        // Sign In Link
                        signInLink
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .alert("Thông báo", isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    authViewModel.errorMessage = nil
                }
            } message: {
                Text(authViewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Header Image
    private var headerImage: some View {
        ZStack(alignment: .bottom) {
            Image("yoga_header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .clipped()
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground).opacity(0),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        }
        .frame(height: 220)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Tạo tài khoản")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Bắt đầu hành trình sức khỏe của bạn")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("example@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Mật khẩu")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("Nhập mật khẩu", text: $password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Nhập mật khẩu", text: $password)
                            .textContentType(.newPassword)
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Password strength indicator
                if !password.isEmpty {
                    PasswordStrengthView(password: password)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Xác nhận mật khẩu")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    if showConfirmPassword {
                        TextField("Nhập lại mật khẩu", text: $confirmPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Nhập lại mật khẩu", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    
                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Password match indicator
                if !confirmPassword.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password == confirmPassword ? .green : .red)
                            .font(.system(size: 12))
                        
                        Text(password == confirmPassword ? "Mật khẩu khớp" : "Mật khẩu không khớp")
                            .font(.system(size: 12))
                            .foregroundColor(password == confirmPassword ? .green : .red)
                    }
                }
            }
        }
    }
    
    // MARK: - Terms Checkbox
    private var termsCheckbox: some View {
        Button {
            agreeToTerms.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreeToTerms ? .blue : .secondary)
                    .font(.system(size: 20))
                
                Text("Tôi đồng ý với ")
                    .foregroundColor(.secondary)
                +
                Text("Điều khoản sử dụng")
                    .foregroundColor(.blue)
                +
                Text(" và ")
                    .foregroundColor(.secondary)
                +
                Text("Chính sách bảo mật")
                    .foregroundColor(.blue)
            }
            .font(.system(size: 14))
            .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Sign Up Button
    private var signUpButton: some View {
        Button {
            Task {
                await authViewModel.signUp(email: email, password: password, confirmPassword: confirmPassword)
                if authViewModel.isAuthenticated {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Đăng ký")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFormValid ? Color.blue : Color.blue.opacity(0.5))
            )
        }
        .disabled(!isFormValid || authViewModel.isLoading)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword && agreeToTerms
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
            
            Text("Hoặc đăng ký với")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .layoutPriority(1)
            
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Login Buttons
    private var socialLoginButtons: some View {
        HStack(spacing: 16) {
            // Google Button
            Button {
                // TODO: Implement Google Sign Up
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Google")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Apple Button
            Button {
                // TODO: Implement Apple Sign Up
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                    Text("Apple")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Sign In Link
    private var signInLink: some View {
        HStack(spacing: 4) {
            Text("Đã có tài khoản?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Đăng nhập")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Password Strength View
struct PasswordStrengthView: View {
    let password: String
    
    private var strength: (level: Int, text: String, color: Color) {
        var level = 0
        
        if password.count >= 6 { level += 1 }
        if password.count >= 8 { level += 1 }
        if password.contains(where: { $0.isNumber }) { level += 1 }
        if password.contains(where: { $0.isUppercase }) { level += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) { level += 1 }
        
        switch level {
        case 0...1:
            return (level, "Yếu", .red)
        case 2...3:
            return (level, "Trung bình", .orange)
        case 4...5:
            return (level, "Mạnh", .green)
        default:
            return (0, "Yếu", .red)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < strength.level ? strength.color : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
            
            Text("Độ mạnh: \(strength.text)")
                .font(.system(size: 12))
                .foregroundColor(strength.color)
        }
    }
}

#Preview {
    SignUpView(authViewModel: AuthViewModel())
}

