//
//  CallShortcutWidget.swift
//  CallShortcutWidget
//
//  Created by DS on 7/22/26.
//

import SwiftUI
import WidgetKit

private enum CallShortcutWidgetConfiguration {
    static let appGroupID = "group.com.Talkie.app"
    static let scenarioTitleKey = "widget.currentScenario.title"
    static let callerNameKey = "widget.currentScenario.callerName"
    static let deepLinkURL = URL(string: "myapp://call")!
}

struct CallShortcutWidgetEntry: TimelineEntry {
    let date: Date
    let scenarioTitle: String
    let callerName: String
}

struct CallShortcutWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CallShortcutWidgetEntry {
        CallShortcutWidgetEntry(
            date: Date(),
            scenarioTitle: "시나리오 제목",
            callerName: "엄마"
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (CallShortcutWidgetEntry) -> Void
    ) {
        completion(makeEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<CallShortcutWidgetEntry>) -> Void
    ) {
        let entry = makeEntry()
        let nextRefreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: Date()
        ) ?? Date().addingTimeInterval(1_800)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefreshDate)
            )
        )
    }

    private func makeEntry() -> CallShortcutWidgetEntry {
        let sharedDefaults = UserDefaults(
            suiteName: CallShortcutWidgetConfiguration.appGroupID
        )

        let scenarioTitle = sharedDefaults?.string(
            forKey: CallShortcutWidgetConfiguration.scenarioTitleKey
        )

        let callerName = sharedDefaults?.string(
            forKey: CallShortcutWidgetConfiguration.callerNameKey
        )

        return CallShortcutWidgetEntry(
            date: Date(),
            scenarioTitle: scenarioTitle?.nilIfBlank ?? "시나리오 제목",
            callerName: callerName?.nilIfBlank ?? "엄마"
        )
    }
}

struct CallShortcutWidgetEntryView: View {
    let entry: CallShortcutWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.scenarioTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(entry.callerName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Link(destination: CallShortcutWidgetConfiguration.deepLinkURL) {
                ZStack {
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.34, blue: 0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("선택한 시나리오로 가상 통화 시작")
        }
        .padding(18)
        .containerBackground(for: .widget) {
            Color(red: 0.11, green: 0.11, blue: 0.11)
        }
    }
}

struct CallShortcutWidget: Widget {
    let kind = "CallShortcutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CallShortcutWidgetProvider()
        ) { entry in
            CallShortcutWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Talkie 통화 바로가기")
        .description("선택된 시나리오로 가상 통화를 빠르게 시작합니다.")
        .supportedFamilies([.systemSmall])
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview(as: .systemSmall) {
    CallShortcutWidget()
} timeline: {
    CallShortcutWidgetEntry(
        date: .now,
        scenarioTitle: "시나리오 제목",
        callerName: "엄마"
    )
}
