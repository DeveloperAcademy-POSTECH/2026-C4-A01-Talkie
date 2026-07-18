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
                        
                        Button{
                            isShowingCreateView = true
                        } label : {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.white)
                            //                        }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
//                    scenarioCount
                    Text("총 \(scenarios.count)개")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
//                    scenarioList
                    ScrollView{
                        LazyVStack(spacing: 16) {
                            ForEach(scenarios) { scenario in
                                NavigationLink {
                                    ScriptEditView(
                                        scenario: scenario,
                                        modelContext: modelContext
                                    )
                                } label: {
                                    ScenarioCardView(scenario: scenario)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $isShowingCreateView) {
                ScenarioCreateView()
            }
        }
    }
}

#Preview {
    ScenarioView()
        .modelContainer(for: [
            Scenario.self,
            CallerProfile.self,
            ScriptLine.self,
            AudioClipMetadata.self
        ], inMemory: true)
}
