//
//  ForgotPasswordView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var emailSent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: emailSent ? "checkmark.circle.fill" : "lock.rotation")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
                
                // Title
                VStack(spacing: 12) {
                    Text(emailSent ? "Đã gửi email!" : "Quên mật khẩu?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(emailSent 
                         ? "Vui lòng kiểm tra hộp thư của bạn và làm theo hướng dẫn để đặt lại mật khẩu."
                         : "Nhập email của bạn và chúng tôi sẽ gửi link đặt lại mật khẩu.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if !emailSent {
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
                    .padding(.horizontal, 24)
                    
                    // Send Button
                    Button {
                        Task {
                            await authViewModel.resetPassword(email: email)
                            if authViewModel.errorMessage?.contains("Đã gửi") == true {
                                withAnimation {
                                    emailSent = true
                                }
                                authViewModel.errorMessage = nil
                            }
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Gửi link đặt lại")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(email.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        )
                    }
                    .disabled(email.isEmpty || authViewModel.isLoading)
                    .padding(.horizontal, 24)
                } else {
                    // Back to Login Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Quay lại đăng nhập")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                Spacer()
            }
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
            .alert("Lỗi", isPresented: .init(
                get: { authViewModel.errorMessage != nil && !authViewModel.errorMessage!.contains("Đã gửi") },
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
}

#Preview {
    ForgotPasswordView(authViewModel: AuthViewModel())
}

