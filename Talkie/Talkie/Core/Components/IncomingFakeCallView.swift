//
//  IncomingFakeCallView.swift
//  Talkie
//

import SwiftUI

struct IncomingFakeCallView: View {
    let profile: VirtualCallerProfile
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                callerHeader
                    .padding(.top, 52)

                Spacer(minLength: 24)

                VStack(spacing: 34) {
                    secondaryActions
                    primaryActions
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 36)
            .frame(maxWidth: 520)
        }
        .preferredColorScheme(.dark)
    }

    private var callerHeader: some View {
        VStack(spacing: 8) {
            Text("Talkie 음성통화")
                .font(Font.pretendard(.medium, size: 22))
                .foregroundStyle(.white.opacity(0.68))

            Text(profile.displayName)
                .font(Font.pretendard(.bold, size: 36))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Talkie 음성통화, \(profile.displayName)에게서 걸려온 전화")
    }

    private var secondaryActions: some View {
        HStack {
            CallActionButton(
                title: "입력하여\n응답하기",
                systemImage: "arrowshape.turn.up.left.fill",
                diameter: 48,
                iconSize: 21,
                backgroundColor: .white.opacity(0.12),
                showsBorder: true,
                isEnabled: false,
                action: {}
            )

            Spacer()

            CallActionButton(
                title: "더 보기",
                systemImage: "ellipsis",
                diameter: 48,
                iconSize: 22,
                backgroundColor: .white.opacity(0.12),
                showsBorder: true,
                isEnabled: false,
                action: {}
            )
        }
    }

    private var primaryActions: some View {
        HStack {
            CallActionButton(
                title: "거절",
                systemImage: "phone.down.fill",
                diameter: 80,
                iconSize: 32,
                backgroundColor: Color(red: 0.93, green: 0.17, blue: 0.21),
                action: onDecline
            )

            Spacer()

            CallActionButton(
                title: "응답",
                systemImage: "phone.fill",
                diameter: 80,
                iconSize: 32,
                backgroundColor: Color(red: 0.20, green: 0.78, blue: 0.35),
                action: onAccept
            )
        }
    }
}

private struct CallActionButton: View {
    let title: String
    let systemImage: String
    let diameter: CGFloat
    let iconSize: CGFloat
    let backgroundColor: Color
    var showsBorder = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: diameter, height: diameter)
                    .background(backgroundColor, in: Circle())
                    .overlay {
                        if showsBorder {
                            Circle()
                                .stroke(.white.opacity(0.52), lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(1)
            .contentShape(Circle())

            Text(title)
                .font(Font.pretendard(.regular, size: 17))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 108)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
        .accessibilityAddTraits(.isButton)
    }
}

struct CallScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.09, blue: 0.10),
                Color(red: 0.16, green: 0.12, blue: 0.11),
                Color(red: 0.29, green: 0.20, blue: 0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(.black.opacity(0.12))
    }
}

#Preview("Incoming call") {
    IncomingFakeCallView(
        profile: .preview,
        onAccept: {},
        onDecline: {}
    )
}
