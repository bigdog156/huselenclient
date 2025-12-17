//
//  PhysicalInfoStepView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct PhysicalInfoStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showDatePicker = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Illustration
                illustrationSection
                    .frame(maxWidth: .infinity)
                
                // Height
                heightSection
                
                // Weight
                weightSection
                
                // Birth Date
                birthDateSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin cơ thể")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Giúp chúng mình tính toán chế độ tập luyện phù hợp với bạn.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Illustration Section
    private var illustrationSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
            
            Image(systemName: "figure.stand")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Height Section
    private var heightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chiều cao")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: "ruler")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField("170", text: $viewModel.height)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16))
                
                Text("cm")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Weight Section
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cân nặng")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: "scalemass")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField("65", text: $viewModel.weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16))
                
                Text("kg")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Birth Date Section
    private var birthDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ngày sinh")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Button {
                showDatePicker.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(dateFormatter.string(from: viewModel.birthDate))
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            
            if showDatePicker {
                DatePicker(
                    "",
                    selection: $viewModel.birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "vi_VN"))
            }
        }
        .animation(.easeInOut, value: showDatePicker)
    }
}

#Preview {
    PhysicalInfoStepView(viewModel: OnboardingViewModel())
}

