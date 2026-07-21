//
//  MyPageView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAutoRecordingEnabled = true
    @State private var isiCloudSyncEnabled = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 28) {
                    navigationBar
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("안전 연락망")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        NavigationLink {
                            SafetyContactListView()
                        } label: {
                            row("안전 연락망 모두 보기")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("이전 통화내역 보기")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        row("모든 통화내역 보기", trailingText: "9")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("자동 녹음")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Toggle("가상 통화 시 자동 녹음", isOn: $isAutoRecordingEnabled)
                            .padding()
                            .background(Constants.grey700)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("iCloud 동기화")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Toggle("iCloud 동기화", isOn: $isiCloudSyncEnabled)
                            .padding()
                            .background(Constants.grey700)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationBarBackButtonHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}

private extension MyPageView {
    var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("뒤로가기")
            
            Spacer()
            
            Text("마이페이지")
                .font(.headline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Color.clear
                .frame(width: 28, height: 28)
        }
    }
    
    func row(
        _ title: String,
        trailingText: String? = nil
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let trailingText {
                Text(trailingText)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding()
        .background(Constants.grey700)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MyPageView()
}
