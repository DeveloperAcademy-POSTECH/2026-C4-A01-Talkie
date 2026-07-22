//
//  ScenarioCardView.swift
//  Talkie
//
//  Created by DS on 7/17/26.
//

import SwiftUI
import SwiftData

struct ScenarioCardView: View {
    let scenario: ScenarioContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.title)
                    .font(Font.custom("Pretendard", size: 18).weight(.semibold))
                    .foregroundColor(Constants.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("발화자  \(scenario.callerName)")
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(Constants.grey500)
                    .lineLimit(1)
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
            
            Text(joinedScriptLines)
                .font(Font.custom("Pretendard", size: 14))
                .foregroundColor(Constants.textSecondary)
                .lineLimit(2)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Constants.grey700)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private var joinedScriptLines: String {
        scenario.scriptPreview
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Scenario.self,
        ScriptLine.self,
        configurations: config
    )
    
    let dummyScenario = Scenario(title: "기본 제공 시나리오 제목", callerName: "사용자 설정 이름")
    
    let line1 = ScriptLine(text: "시나리오 내용 첫 문장", sortOrder: 0, scenario: dummyScenario)
    let line2 = ScriptLine(text: "시나리오 두 번째 문장", sortOrder: 1, scenario: dummyScenario)
    let line3 = ScriptLine(text: "시나리오 세 번째 문장", sortOrder: 2, scenario: dummyScenario)
    let line4 = ScriptLine(text: "시나리오 네 번째 문장", sortOrder: 3, scenario: dummyScenario)
    let line5 = ScriptLine(text: "시나리오 다섯 번째 문장", sortOrder: 4, scenario: dummyScenario)
    
    dummyScenario.scriptLines = [line1, line2, line3, line4, line5]
    
    container.mainContext.insert(dummyScenario)
    
    return ScenarioCardView(scenario: dummyScenario.content)
        .padding()
        .background(.black)
        .modelContainer(container)
}
