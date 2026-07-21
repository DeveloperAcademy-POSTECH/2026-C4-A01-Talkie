//
//  OnboardingData.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import Foundation

struct OnboardingData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String?
}

extension OnboardingData {
    static let pages: [OnboardingData] = [
        OnboardingData(
            title: "Talkie 시작하기",
            description: "필요한 순간 자연스럽게 사용할 수 있는 통화 시나리오를 준비합니다.",
            imageName: nil
        ),
        OnboardingData(
            title: "시나리오 만들기",
            description: "상황에 맞는 대사를 만들고, 원하는 순서로 정리할 수 있습니다.",
            imageName: nil
        ),
        OnboardingData(
            title: "목소리 녹음하기",
            description: "대사별로 목소리를 녹음해 더 자연스러운 통화 흐름을 만듭니다.",
            imageName: nil
        )
    ]
}
