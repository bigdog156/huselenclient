//
//  LoginView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

enum LoginMethod: String, CaseIterable {
    case phone = "Số điện thoại"
    case email = "Email"
}

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedMethod: LoginMethod = .email
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image
                headerImage
                
                // Content
                VStack(spacing: 24) {
                    // Title
                    titleSection
                    
                    // Login Method Toggle
                    methodToggle
                    
                    // Form Fields
                    formFields
                    
                    // Forgot Password
                    forgotPasswordLink
                    
                    // Sign In Button
                    signInButton
                    
                    // Divider
                    dividerSection
                    
                    // Social Login Buttons
                    socialLoginButtons
                    
                    // Sign Up Link
                    signUpLink
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showSignUp) {
            SignUpView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authViewModel: authViewModel)
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
    
    // MARK: - Header Image
    private var headerImage: some View {
        ZStack(alignment: .bottom) {
            Image("yoga_header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 280)
                .clipped()
            
            // Gradient overlay for smooth transition
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
        .frame(height: 280)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Chào mừng trở lại!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Tiếp tục hành trình của bạn ngay hôm nay.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Method Toggle
    private var methodToggle: some View {
        HStack(spacing: 0) {
            ForEach(LoginMethod.allCases, id: \.self) { method in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMethod = method
                    }
                } label: {
                    Text(method.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedMethod == method ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMethod == method ? Color(.systemBackground) : Color.clear)
                                .shadow(color: selectedMethod == method ? Color.black.opacity(0.08) : Color.clear, radius: 4, x: 0, y: 2)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
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
                            .textContentType(.password)
                    } else {
                        SecureField("Nhập mật khẩu", text: $password)
                            .textContentType(.password)
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
            }
        }
    }
    
    // MARK: - Forgot Password Link
    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button {
                showForgotPassword = true
            } label: {
                Text("Quên mật khẩu?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Sign In Button
    private var signInButton: some View {
        Button {
            Task {
                await authViewModel.signIn(email: email, password: password)
            }
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Đăng nhập")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue)
            )
        }
        .disabled(authViewModel.isLoading)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
            
            Text("Hoặc đăng nhập với")
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
                // TODO: Implement Google Sign In
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
                // TODO: Implement Apple Sign In
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
    
    // MARK: - Sign Up Link
    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Chưa có tài khoản?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Button {
                showSignUp = true
            } label: {
                Text("Đăng ký ngay")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}

