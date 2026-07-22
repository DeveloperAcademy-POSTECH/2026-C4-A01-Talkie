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
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Text("총 \(scenarios.count)개")
                        .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                        .foregroundColor(Constants.textTertiary)
                        .frame(width: 95, height: 24, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ScrollView{
                        LazyVStack(spacing: 16) {
                            ForEach(scenarios) { scenario in
                                NavigationLink {
                                    ScenarioDetailView(scenario: scenario)
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
                ScenarioCreateView {
                    isShowingCreateView = false
                }
            }
        }
    }
}

#Preview {
    ScenarioView()
        .modelContainer(for: [
            Scenario.self,
            ScriptLine.self,
            AudioClipMetadata.self
        ], inMemory: true)
}
