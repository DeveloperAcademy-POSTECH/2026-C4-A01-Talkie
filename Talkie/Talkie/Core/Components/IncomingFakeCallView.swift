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

            VStack(spacing: 0) {
                callerHeader
                    .padding(.top, 58)

                Spacer(minLength: 40)

                secondaryActions

                Spacer(minLength: 36)

                primaryActions
                    .padding(.bottom, 46)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: 520)
        }
        .ignoresSafeArea()
        .statusBarHidden()
    }

    private var callerHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: profile.imageSystemName ?? "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 112, height: 112)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(profile.displayName)
                    .font(.system(size: 39, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(profile.relationship)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName), \(profile.relationship)에서 걸려온 전화")
    }

    private var secondaryActions: some View {
        HStack {
            CallActionButton(
                title: "나중에 보기",
                systemImage: "bell.fill",
                backgroundColor: .white.opacity(0.18),
                action: {}
            )
            .disabled(true)

            Spacer()

            CallActionButton(
                title: "메시지",
                systemImage: "message.fill",
                backgroundColor: .white.opacity(0.18),
                action: {}
            )
            .disabled(true)
        }
    }

    private var primaryActions: some View {
        HStack {
            CallActionButton(
                title: "거절",
                systemImage: "phone.down.fill",
                backgroundColor: Color(red: 0.93, green: 0.17, blue: 0.21),
                action: onDecline
            )

            Spacer()

            CallActionButton(
                title: "응답",
                systemImage: "phone.fill",
                backgroundColor: Color(red: 0.20, green: 0.78, blue: 0.35),
                action: onAccept
            )
        }
    }
}

private struct CallActionButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(backgroundColor, in: Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Text(title)
                .font(.footnote)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 98)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

struct CallScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.22, green: 0.27, blue: 0.25),
                Color(red: 0.08, green: 0.10, blue: 0.10),
                .black,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(.ultraThinMaterial.opacity(0.18))
    }
}

#Preview("Incoming call") {
    IncomingFakeCallView(
        profile: .preview,
        onAccept: {},
        onDecline: {}
    )
}
