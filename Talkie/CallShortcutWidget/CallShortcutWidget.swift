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

private enum WidgetColor {
    static let grey400 = Color(red: 0.63, green: 0.63, blue: 0.63)
    static let grey700 = Color(red: 0.17, green: 0.17, blue: 0.17)
    static let main500 = Color(red: 1.0, green: 0.36, blue: 0.11)
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
        VStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.scenarioTitle)
                    .font(Font.custom("Pretendard", size: 16).weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Text(entry.callerName)
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(WidgetColor.grey400)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Spacer(minLength: 0)

            Link(destination: CallShortcutWidgetConfiguration.deepLinkURL) {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                }
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                .background(WidgetColor.main500)
                .cornerRadius(100)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("선택한 시나리오로 가상 통화 시작")
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black, location: 0),
                    Gradient.Stop(
                        color: Color(red: 0.4, green: 0.4, blue: 0.4),
                        location: 1
                    ),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .background(WidgetColor.grey700)
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
