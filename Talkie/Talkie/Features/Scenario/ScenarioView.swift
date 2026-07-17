//
//  ScenarioListView.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct ScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Scenario.createdAt, order: .reverse)
    private var scenarios: [Scenario]

    @State private var isShowingCreateView = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("시나리오")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
//                        Button(action: addMockScenario) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.white)
//                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
//                    scenarioCount
//
//                    scenarioList

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $isShowingCreateView) {
//                ScenarioCreateView()
            }
        }
    }
}

#Preview {
    ScenarioView()
}
