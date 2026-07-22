//
//  WidgetScenarioStore.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import Foundation
import WidgetKit

enum WidgetScenarioStore {
    static let appGroupID = "group.com.Talkie.app"
    static let scenarioTitleKey = "widget.currentScenario.title"
    static let callerNameKey = "widget.currentScenario.callerName"
    static let callDeepLink = "myapp://call"

    static func save(scenario: Scenario) {
        save(
            scenarioTitle: scenario.title,
            callerName: scenario.callerName
        )
    }

    static func save(scenario: ScenarioContent) {
        save(
            scenarioTitle: scenario.title,
            callerName: scenario.callerName
        )
    }

    static func save(
        scenarioTitle: String,
        callerName: String
    ) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("App Group UserDefaults를 열 수 없습니다: \(appGroupID)")
            return
        }

        sharedDefaults.set(scenarioTitle, forKey: scenarioTitleKey)
        sharedDefaults.set(callerName, forKey: callerNameKey)
        sharedDefaults.synchronize()

        print("위젯 시나리오 저장: \(scenarioTitle), 발화자: \(callerName)")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
