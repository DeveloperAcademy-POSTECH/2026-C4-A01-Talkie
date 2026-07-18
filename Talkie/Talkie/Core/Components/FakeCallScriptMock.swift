//
//  FakeCallScriptMock.swift
//  Talkie
//


import Foundation

struct VirtualCallerProfile: Identifiable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    var relationship: String
    var imageSystemName: String?
}

struct FakeCallScriptLine: Identifiable, Hashable, Sendable {
    let id: UUID
    let profileID: UUID
    var order: Int
    var text: String
    var audioClipID: UUID?
}

struct VoiceClipMetadata: Identifiable, Hashable, Sendable {
    let id: UUID
    let scriptLineID: UUID
    var localFileName: String?
    var duration: TimeInterval
}

protocol FakeCallScriptRepository: Sendable {
    func activeProfile() async throws -> VirtualCallerProfile
    func scriptLines(for profileID: UUID) async throws -> [FakeCallScriptLine]
    func voiceClip(for lineID: UUID) async throws -> VoiceClipMetadata?
}

struct MockFakeCallScriptRepository: FakeCallScriptRepository {
    private let profile: VirtualCallerProfile
    private let lines: [FakeCallScriptLine]

    init(
        displayName: String = "엄마",
        relationship: String = "휴대전화"
    ) {
        let profileID = UUID(uuidString: "8E37F9D5-1F34-4882-96C6-9B85F4A80F11")!

        profile = VirtualCallerProfile(
            id: profileID,
            displayName: displayName,
            relationship: relationship,
            imageSystemName: "person.crop.circle.fill"
        )

        lines = [
            FakeCallScriptLine(
                id: UUID(uuidString: "50C29606-0937-4C83-9B5B-7D164F79E4A8")!,
                profileID: profileID,
                order: 0,
                text: "어, 지금 어디쯤이야?",
                audioClipID: nil
            ),
            FakeCallScriptLine(
                id: UUID(uuidString: "02BF9A31-FA38-4148-A2FA-A766E620D07D")!,
                profileID: profileID,
                order: 1,
                text: "그래. 천천히 와. 거의 다 오면 다시 말해 줘.",
                audioClipID: nil
            ),
            FakeCallScriptLine(
                id: UUID(uuidString: "611FB19B-BF04-475B-8D5E-153496588BAD")!,
                profileID: profileID,
                order: 2,
                text: "알겠어. 내가 기다리고 있을게.",
                audioClipID: nil
            ),
        ]
    }

    func activeProfile() async throws -> VirtualCallerProfile {
        profile
    }

    func scriptLines(for profileID: UUID) async throws -> [FakeCallScriptLine] {
        lines
            .filter { $0.profileID == profileID }
            .sorted { $0.order < $1.order }
    }

    func voiceClip(for lineID: UUID) async throws -> VoiceClipMetadata? {
        nil
    }
}

extension VirtualCallerProfile {
    static let preview = VirtualCallerProfile(
        id: UUID(uuidString: "8E37F9D5-1F34-4882-96C6-9B85F4A80F11")!,
        displayName: "엄마",
        relationship: "휴대전화",
        imageSystemName: "person.crop.circle.fill"
    )
}
