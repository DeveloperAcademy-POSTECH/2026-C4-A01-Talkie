//
//  ScenarioListView.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//
import SwiftUI
import SwiftData

struct ScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Scenario.createdAt, order: .reverse)
    private var scenarios: [Scenario]

    @State private var isShowingCreateView = false

    private var totalScenarioCount: Int {
        PresetScenarioCatalog.all.count + scenarios.count
    }

    var body: some View {
        NavigationStack {
            DarkScreen {
                VStack(spacing: 0) {
                    MainTabHeader(title: "시나리오") {
                        Button {
                            isShowingCreateView = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Constants.textPrimary)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("시나리오 추가")
                    }
                    .padding(.top, 32)


                    Text("총 \(totalScenarioCount)개")
                        .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                        .foregroundColor(Constants.textTertiary)
                        .frame(width: 95, height: 24, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    ScrollView{
                        LazyVStack(spacing: 16) {
                            ForEach(scenarios) { scenario in
                                NavigationLink {
                                    ScenarioDetailView(scenario: scenario)
                                } label: {
                                    ScenarioCardView(scenario: scenario.content)
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(PresetScenarioCatalog.all) { preset in
                                NavigationLink {
                                    ScenarioDetailView(preset: preset)
                                } label: {
                                    ScenarioCardView(scenario: preset.content)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $isShowingCreateView) {
                ScenarioCreateView {
                    isShowingCreateView = false
                }
            }
        }
    }
}
