//
//  WidgetInstallUI.swift
//  Talkie
//
//  Created by GRACE on 7/21/26.
//

import SwiftUI

struct WidgetInstallUI: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                WidgetInstallStyle.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header(topInset: proxy.safeAreaInsets.top)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            WidgetInstallStepView(
                                number: "1",
                                copy: .step1,
                                imageName: "widget_install_step_1",
                                imageWidth: imageWidth(for: proxy.size.width),
                                topPadding: 50
                            )

                            WidgetInstallStepView(
                                number: "2",
                                copy: .step2,
                                imageName: "widget_install_step_2",
                                imageWidth: imageWidth(for: proxy.size.width),
                                topPadding: 52
                            )

                            WidgetInstallStepView(
                                number: "3",
                                copy: .step3,
                                imageName: "widget_install_step_3",
                                imageWidth: imageWidth(for: proxy.size.width),
                                topPadding: 62
                            )

                            WidgetInstallStepView(
                                number: "4",
                                copy: .step4,
                                imageName: "widget_install_step_4",
                                imageWidth: imageWidth(for: proxy.size.width),
                                topPadding: 66
                            )
                        }
                        .padding(.bottom, 70)
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.horizontal, 24, for: .scrollContent)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func header(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width:36, height:36)
                        .background {
                            Circle()
                                .fill(.white.opacity(0.04))
                                .stroke(.white.opacity(0.22), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")

                Spacer()

                Text("위젯 설정 방법")
                    .font(Font.pretendard(.semiBold, size: 16))
                    .foregroundStyle(.white)

                Spacer()

                Color.clear
                    .frame(width:36, height:36)
            }
            .padding(.horizontal, 16)
            .padding(.top, topInset + 26)
            .padding(.bottom, 14)

            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private func imageWidth(for screenWidth: CGFloat) -> CGFloat {
        min(screenWidth - 48, 350)
    }
}

private struct WidgetInstallStepView: View {
    let number: String
    let copy: AttributedString
    let imageName: String
    let imageWidth: CGFloat
    let topPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top, spacing: 16) {
                Text(number)
                    .font(Font.pretendard(.bold, size: 16))
                    .foregroundStyle(WidgetInstallStyle.point)
                    .frame(width: 28, height: 26)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.08))
                    }

                Text(copy)
                    .font(Font.pretendard(.semiBold, size: 16))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, topPadding)
    }
}

private enum WidgetInstallStyle {
    static let background = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let point = Color(red: 1.0, green: 0.32, blue: 0.0)
}

private extension AttributedString {
    static let step1 = highlighted([
        ("홈 화면을 길게 눌러 왼쪽 위의\n", nil),
        ("편집", WidgetInstallStyle.point),
        (" 버튼을 누르고 ", nil),
        ("위젯 추가", WidgetInstallStyle.point),
        ("를 선택해주세요.", nil)
    ])

    static let step2 = highlighted([
        ("위젯 목록에서 ", nil),
        ("Talkie", WidgetInstallStyle.point),
        ("를 찾아 선택합니다.", nil)
    ])

    static let step3 = highlighted([
        ("위젯 추가를 눌러주세요.", nil)
    ])

    static let step4 = highlighted([
        ("홈 화면에서 바로 ", nil),
        ("가상 전화", WidgetInstallStyle.point),
        ("를 사용해보세요.", nil)
    ])

    static func highlighted(_ fragments: [(String, Color?)]) -> AttributedString {
        fragments.reduce(into: AttributedString()) { result, fragment in
            var text = AttributedString(fragment.0)

            if let color = fragment.1 {
                text.foregroundColor = color
            }

            result += text
        }
    }
}

#Preview {
    WidgetInstallUI()
        .frame(width: 402, height: 874)
}
