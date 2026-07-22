//
//  FakeCallLiveActivityWidget.swift
//  TalkieLiveActivity
//
//  System-owned presentations for an ongoing fake call. The timer is derived
//  from startedAt, so it keeps advancing while the app is in the background.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct FakeCallLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FakeCallActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.callerName, systemImage: "phone.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    elapsedTimer(startedAt: context.state.startedAt)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("가상 통화 중")
                            .foregroundStyle(.secondary)

                        Spacer()

                        CallWaveformView()
                    }
                    .font(.subheadline)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                    elapsedTimer(startedAt: context.state.startedAt)
                        .monospacedDigit()
                }
                .font(.caption.bold())
                .foregroundStyle(.green)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("가상 통화 시간")
            } compactTrailing: {
                CallWaveformView()
            } minimal: {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("가상 통화 중")
            }
            .keylineTint(.green)
        }
    }

    private func lockScreenView(
        context: ActivityViewContext<FakeCallActivityAttributes>
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "phone.fill")
                .font(.title3.bold())
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.callerName)
                    .font(.headline)
                    .lineLimit(1)

                Text("가상 통화 중")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            elapsedTimer(startedAt: context.state.startedAt)
                .font(.title3.monospacedDigit())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(context.attributes.callerName)님과 가상 통화 중")
    }

    private func elapsedTimer(startedAt: Date) -> Text {
        Text(startedAt, style: .timer)
    }
}

private struct CallWaveformView: View {
    private let heights: [CGFloat] = [8, 14, 20, 12, 18, 9]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(heights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? Color.green : Color.yellow)
                    .frame(width: 3, height: height)
            }
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }
}
