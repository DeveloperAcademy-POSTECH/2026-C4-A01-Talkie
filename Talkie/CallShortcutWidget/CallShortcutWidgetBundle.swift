//
//  CallShortcutWidgetBundle.swift
//  CallShortcutWidget
//
//  Created by DS on 7/22/26.
//

import WidgetKit
import SwiftUI

@main
struct CallShortcutWidgetBundle: WidgetBundle {
    var body: some Widget {
        CallShortcutWidget()
        // Live Activity도 기존 widget extension에서 함께 제공한다.
        // 별도 extension을 만들지 않아 bundle ID와 provisioning profile을 추가하지 않는다.
        FakeCallLiveActivityWidget()
    }
}
