//
//  WidgetInstallBannerView.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import SwiftUI

struct WidgetInstallBannerView: View {
    var body: some View {
        HStack(spacing: 22) {
            icon

            VStack(alignment: .leading, spacing: 8) {
                Text("위젯으로 간편하게 가상통화를 시작하세요!")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 6) {
                    Text("설치방법 보러가기")

                    Image(systemName: "chevron.right")
                        .font(.system(size: 19, weight: .medium))
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.30))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Color(red: 0.17, green: 0.17, blue: 0.17))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("위젯 설치 안내, 설치방법 보러가기")
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 72, height: 72)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .frame(width: 44, height: 44)

            Image(systemName: "phone.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Constants.main500)
        }
    }
}

#Preview {
    WidgetInstallBannerView()
        .padding()
        .background(Constants.grey800)
        .preferredColorScheme(.dark)
}
