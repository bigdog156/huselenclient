//
//  WeightTrackingView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI
import Charts

struct WeightTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WeightTrackingViewModel()
    
    let userId: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Input Card
                    inputCard
                    
                    // Chart Card
                    chartCard
                    
                    // Recent History
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Theo dõi cân nặng")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.loadWeightLogs(userId: userId)
            }
            .alert("Lỗi", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Input Card
    private var inputCard: some View {
        VStack(spacing: 20) {
            Text("Cập nhật hôm nay")
                .font(.system(size: 20, weight: .bold))
            
            // Weekly limit badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Giới hạn nhập: \(viewModel.logsThisWeek)/2 lần tuần này")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Weight Input Field
            HStack(alignment: .bottom, spacing: 8) {
                TextField("00.0", text: $viewModel.inputWeight)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(viewModel.inputWeight.isEmpty ? Color(.systemGray3) : .primary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
                
                Text("kg")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
            .padding(.bottom, 8)
            
            // Underline
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
                .frame(maxWidth: 220)
            
            // Save Button
            Button {
                Task {
                    if let weight = viewModel.validateWeight(viewModel.inputWeight) {
                        await viewModel.saveWeightLog(
                            userId: userId,
                            weight: weight
                        )
                    } else {
                        viewModel.errorMessage = "Vui lòng nhập cân nặng hợp lệ (20-300 kg)"
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Lưu cân nặng")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.canLogMoreThisWeek && !viewModel.inputWeight.isEmpty ? Color.blue : Color.gray)
                )
            }
            .disabled(!viewModel.canLogMoreThisWeek || viewModel.isSaving || viewModel.inputWeight.isEmpty)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Biểu đồ phát triển")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Text("Tháng \(Calendar.current.component(.month, from: Date()))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if viewModel.chartData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Chưa có dữ liệu")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                // Line Chart
                WeightLineChart(data: viewModel.chartData)
                    .frame(height: 200)
            }
            
            Text("Biểu đồ hiển thị sự thay đổi theo thời gian, giúp bạn hiểu rõ hơn về cơ thể mình.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lịch sử gần đây")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 4)
            
            if viewModel.weightLogs.isEmpty {
                Text("Chưa có lịch sử")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.weightLogs.prefix(10).enumerated()), id: \.element.id) { index, log in
                        WeightHistoryRow(log: log)
                        
                        if index < min(9, viewModel.weightLogs.count - 1) {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
            }
        }
    }
}

// MARK: - Weight Line Chart
struct WeightLineChart: View {
    let data: [WeightChartPoint]
    
    private var minWeight: Double {
        (data.map(\.weight).min() ?? 50) - 2
    }
    
    private var maxWeight: Double {
        (data.map(\.weight).max() ?? 60) + 2
    }
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Ngày", point.dayOfMonth),
                    y: .value("Cân nặng", point.weight)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Ngày", point.dayOfMonth),
                    y: .value("Cân nặng", point.weight)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(50)
            }
            
            // Area under the line
            ForEach(data) { point in
                AreaMark(
                    x: .value("Ngày", point.dayOfMonth),
                    y: .value("Cân nặng", point.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: minWeight...maxWeight)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text(String(format: "%02d", day))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text(String(format: "%.0f", weight))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Weight History Row
struct WeightHistoryRow: View {
    let log: UserWeightLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            
            // Date info
            VStack(alignment: .leading, spacing: 4) {
                Text(log.formattedDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Cập nhật cân nặng")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Weight
            HStack(spacing: 4) {
                Text(String(format: "%.1f", log.weightKg))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("kg")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    WeightTrackingView(userId: "test-user-id")
}

