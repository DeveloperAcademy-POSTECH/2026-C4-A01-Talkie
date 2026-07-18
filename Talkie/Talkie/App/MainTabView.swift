//
//  MainTab.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import SwiftUI

enum MainTab: Hashable {
    case phone
    case scenario
    case sos
}
struct MainTabView: View {
    @State private var selectedTab: MainTab = .phone
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PhoneView()
                .tag(MainTab.phone) // ??
                .tabItem {
                    Label("전화", systemImage: "phone.fill")
                }
            ScenarioView()
                .tag(MainTab.scenario)
                .tabItem {
                    Label("시나리오", systemImage: "recordingtape")
                }
            SOSView()
                .tag(MainTab.sos)
                .tabItem {
                    Label("SOS", systemImage: "light.beacon.max.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
