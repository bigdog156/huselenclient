//
//  JournalView.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

struct JournalView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                }
                
                VStack(spacing: 8) {
                    Text("Nhật ký tập luyện")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Ghi lại hành trình của bạn")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Text("Tính năng đang phát triển...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                Spacer()
                Spacer()
            }
            .padding()
            .navigationTitle("Nhật ký")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    JournalView()
}

