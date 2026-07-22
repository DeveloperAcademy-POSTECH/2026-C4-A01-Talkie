//
//  ScenarioFakeCallScriptRepository.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

/// ScenarioContent를 기존 가상 통화 상태 머신이 이해하는 repository 계약으로 변환합니다.
/// 초기화 시 SwiftData와의 연결을 끊고 값만 복사하므로 통화 도중 원본이 바뀌어도 세션은 안정적입니다.
struct ScenarioFakeCallScriptRepository: FakeCallScriptRepository {
    private let profile: VirtualCallerProfile
    private let lines: [FakeCallScriptLine]
    private let audioSourcesByLineID: [UUID: ScenarioAudioSource]

    init(content: ScenarioContent) {
        let profileID = UUID()
        profile = VirtualCallerProfile(
            id: profileID,
            displayName: content.callerName,
            relationship: "휴대전화",
            imageSystemName: "person.crop.circle.fill"
        )

        var audioSources: [UUID: ScenarioAudioSource] = [:]
        lines = content.scriptLines
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { line in
                let lineID = UUID()
                if let audioSource = line.audioSource {
                    audioSources[lineID] = audioSource
                }
                return FakeCallScriptLine(
                    id: lineID,
                    profileID: profileID,
                    order: line.sortOrder,
                    text: line.text,
                    audioClipID: line.audioSource == nil ? nil : lineID
                )
            }
        audioSourcesByLineID = audioSources
    }

    func activeProfile() async throws -> VirtualCallerProfile {
        profile
    }

    func scriptLines(for profileID: UUID) async throws -> [FakeCallScriptLine] {
        lines.filter { $0.profileID == profileID }
    }

    func voiceClip(for lineID: UUID) async throws -> VoiceClipMetadata? {
        guard let source = audioSourcesByLineID[lineID] else {
            return nil
        }

        let url = try ScenarioAudioResolver.url(for: source)
        return VoiceClipMetadata(
            id: lineID,
            scriptLineID: lineID,
            localFileName: url.path,
            duration: 0
        )
    }
}
