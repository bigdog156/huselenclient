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
    @State private var showCamera = false
    
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
            .sheet(isPresented: $showCamera) {
                WeightPhotoCapture(
                    capturedImage: $viewModel.capturedPhoto,
                    isPresented: $showCamera
                )
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
            
            // Action Buttons
            HStack(spacing: 12) {
                // Camera Button
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Chụp hình")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .disabled(!viewModel.canLogMoreThisWeek)
                .opacity(viewModel.canLogMoreThisWeek ? 1 : 0.5)
                
                // Save Button
                Button {
                    Task {
                        if let weight = viewModel.validateWeight(viewModel.inputWeight) {
                            await viewModel.saveWeightLog(
                                userId: userId,
                                weight: weight,
                                photo: viewModel.capturedPhoto
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
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 16))
                            Text("Lưu số đo")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.canLogMoreThisWeek ? Color.blue : Color.gray)
                    )
                }
                .disabled(!viewModel.canLogMoreThisWeek || viewModel.isSaving || viewModel.inputWeight.isEmpty)
            }
            
            // Photo preview if captured
            if let photo = viewModel.capturedPhoto {
                HStack(spacing: 8) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Ảnh đã chụp")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        viewModel.capturedPhoto = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
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
                    .fill(log.inputType == .photo ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: log.inputType == .photo ? "calendar" : "pencil.line")
                    .font(.system(size: 18))
                    .foregroundColor(log.inputType == .photo ? .blue : .gray)
            }
            
            // Date info
            VStack(alignment: .leading, spacing: 4) {
                Text(log.formattedDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(log.inputType?.displayName ?? "Nhập thủ công")
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

// MARK: - Weight Photo Capture
struct WeightPhotoCapture: View {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    @StateObject private var cameraManager = WeightCameraManager()
    
    var body: some View {
        ZStack {
            // Camera Preview
            WeightCameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Overlay
            VStack {
                // Top bar
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    
                    Spacer()
                    
                    Text("Chụp ảnh cân")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Guide text
                Text("Hướng camera vào màn hình cân")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                    )
                
                Spacer()
                
                // Capture button
                Button {
                    cameraManager.capturePhoto { image in
                        if let image = image {
                            capturedImage = image
                            isPresented = false
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// MARK: - Weight Camera Manager
import AVFoundation

class WeightCameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
}

extension WeightCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.captureCompletion?(image)
        }
    }
}

// MARK: - Weight Camera Preview
struct WeightCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> WeightCameraPreviewUIView {
        let view = WeightCameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: WeightCameraPreviewUIView, context: Context) {
        uiView.session = session
    }
}

class WeightCameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            
            DispatchQueue.main.async {
                if self.previewLayer == nil {
                    let layer = AVCaptureVideoPreviewLayer(session: session)
                    layer.videoGravity = .resizeAspectFill
                    layer.frame = self.bounds
                    self.layer.addSublayer(layer)
                    self.previewLayer = layer
                } else {
                    self.previewLayer?.session = session
                }
            }
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

#Preview {
    WeightTrackingView(userId: "test-user-id")
}

