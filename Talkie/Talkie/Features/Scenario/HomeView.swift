//
//  HomeView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Scenario.createdAt, order: .reverse) private var scenarios: [Scenario]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("설정된 가짜 통화 시나리오")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    if let scenario = scenarios.first {
                        Text(scenario.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(scenario.callerProfile.name)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("설정된 시나리오가 없습니다")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.1))
                .cornerRadius(16)
                
                Button {
                    
                } label: {
                    Text("가상 통화 시작")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                
                List {
                    ForEach(scenarios) { scenario in
                        Section {
                            let sortedLines = scenario.scriptLines.sorted {
                                $0.sortOrder < $1.sortOrder
                            }
                            
                            if sortedLines.isEmpty {
                                Text("등록된 대사X")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(sortedLines) { scriptLine in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(scriptLine.sortOrder + 1).")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(scriptLine.text)
                                            
                                            Text(audioStatusText(for: scriptLine))
                                                .font(.caption)
                                                .foregroundStyle(audioStatusColor(for: scriptLine))
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scenario.title)
                                        .font(.headline)
                                    
                                    Text(scenario.callerProfile.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
    
    private func audioStatusText(for scriptLine: ScriptLine) -> String {
        guard let audioMetadata = scriptLine.audioMetadata else {
            return "녹음 없음"
        }
        
        if audioMetadata.audioData == nil {
            return "메타데이터 있음 / 오디오 데이터 없음"
        }
        
        return "녹음 데이터 있음"
    }
    
    private func audioStatusColor(for scriptLine: ScriptLine) -> Color {
        guard let audioMetadata = scriptLine.audioMetadata else {
            return .secondary
        }
        
        return audioMetadata.audioData == nil ? .orange : .green
    }
}

#Preview {
    HomeView()
}
