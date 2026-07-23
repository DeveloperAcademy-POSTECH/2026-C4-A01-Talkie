//
//  OnboardingData.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import Foundation
import SwiftUI

struct OnboardingData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String?
}

extension OnboardingData {
    static let pages: [OnboardingData] = [
        OnboardingData(
            title: "혼자 걷는 밤길도, 혼자가 아니도록",
            description: "전화할 사람이 없을 때 가상 전화를 시작해보세요.",
            imageName: "Onboarding_image1"
        ),
        OnboardingData(
            title: "한 번의 터치로 바로 통화하세요.",
            description: "위젯을 누르면 간편하게 가상 통화를 시작할 수 있어요.",
            imageName: "Onboarding_image2"
        ),
        OnboardingData(
            title: "통화를 끊지 않고 도움을 요청하세요.",
            description: "통화 화면에서 112신고, 위치 공유를 바로 이용할 수 있어요.",
            imageName: "Onboarding_image3"
        ),
        OnboardingData(
            title: "안심할 수 있는 기록까지",
            description: "통화와 함께 음성을 자동 기록해 필요한 순간을 남겨요.",
            imageName: "Onboarding_image4"
        )
    ]
}
