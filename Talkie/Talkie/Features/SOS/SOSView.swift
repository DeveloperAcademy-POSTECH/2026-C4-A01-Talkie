//
//  SOSView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI

struct SOSView: View {
    @State private var sosManager = SOSManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("SOS")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("지금 위험하신가요?")
                    .font(.title2)
                    .bold()
                
                Text("아래 버튼을 눌러 현재 위치 공유 또는 신고를 선택할 수 있어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            statusSection
            
            VStack(spacing: 12) {
                Button {
                    sosManager.shareLocationToContacts()
                } label: {
                    actionRowTitle("안전 연락망에 위치 공유")
                }
                .disabled(sosManager.isLoading || !sosManager.hasEmergencyContacts)
                
                Button {
                    sosManager.sendEmergencySMS112()
                } label: {
                    actionRowTitle("112 문자 신고")
                }
                
                Button {
                    sosManager.call112()
                } label: {
                    actionRowTitle("112 전화 신고")
                }
            }
            
            Spacer()
        }
        .padding(24)
    }
}

private extension SOSView {
    var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("와이어프레임 상태")
                .font(.headline)
            
            Text("isLoading: \(sosManager.isLoading.description)")
            Text("hasEmergencyContacts: \(sosManager.hasEmergencyContacts.description)")
            
            if let locationError = sosManager.locationError {
                Text("locationError: \(locationError.message)")
                    .foregroundStyle(.red)
            } else {
                Text("locationError: nil")
                    .foregroundStyle(.secondary)
            }
            
            if sosManager.isLoading {
                ProgressView("위치 공유 준비 중...")
            }
        }
        .font(.footnote)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    func actionRowTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SOSView()
}
