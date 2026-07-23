//
//  WidgetInstallBannerView.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import SwiftUI

struct WidgetInstallBannerView: View {
    var body: some View {
        HStack(spacing: 16) {
            icon

            VStack(alignment: .leading, spacing: 2) {
                Text("위젯으로 간편하게 가상통화를 시작하세요!")
                    .font(.pretendard(.semiBold, size: 14))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.bottom, 2)

                HStack(spacing: 6) {
                    Text("설치방법 보러가기")
                        .font(.pretendard(.medium, size: 12))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.30))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Constants.grey700)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("위젯 설치 안내, 설치방법 보러가기")
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 36, height: 36)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .frame(width: 28, height: 28)

            Image(systemName: "phone.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Constants.main500)
        }
    }
}

#Preview {
    WidgetInstallBannerView()
        .padding()
        .preferredColorScheme(.dark)
}
