//
//  VoiceActivityGate.swift
//  Talkie
//

import Foundation

struct VoiceActivityGate: Sendable {
    static let speechThresholdRange: ClosedRange<Float> = -60 ... -20

    struct Configuration: Sendable {
        var speechThreshold: Float = -35
        var minimumSpeechDuration: TimeInterval = 0.2
        var silenceDurationToFinish: TimeInterval = 0.5
        var interruptedSpeechTolerance: TimeInterval = 0.12
        var releaseHysteresis: Float = 3
    }

    enum Event: Equatable, Sendable {
        case speechStarted
        case speechEnded
    }

    private(set) var configuration: Configuration
    private var speechCandidateStartedAt: TimeInterval?
    private var lastSpeechDetectedAt: TimeInterval?
    private var hasConfirmedSpeech = false

    init(configuration: Configuration = Configuration()) {
        var configuration = configuration
        configuration.speechThreshold = Self.clampedSpeechThreshold(
            configuration.speechThreshold
        )
        self.configuration = configuration
    }

    var speechThreshold: Float {
        configuration.speechThreshold
    }

    mutating func updateSpeechThreshold(_ threshold: Float) {
        configuration.speechThreshold = Self.clampedSpeechThreshold(threshold)

        if !hasConfirmedSpeech {
            speechCandidateStartedAt = nil
            lastSpeechDetectedAt = nil
        }
    }

    mutating func reset() {
        speechCandidateStartedAt = nil
        lastSpeechDetectedAt = nil
        hasConfirmedSpeech = false
    }

    mutating func process(
        decibels: Float,
        at now: TimeInterval
    ) -> Event? {
        let activeThreshold = hasConfirmedSpeech
            ? configuration.speechThreshold - configuration.releaseHysteresis
            : configuration.speechThreshold

        if decibels >= activeThreshold {
            if speechCandidateStartedAt == nil {
                speechCandidateStartedAt = now
            }

            lastSpeechDetectedAt = now

            if !hasConfirmedSpeech,
               let candidateStart = speechCandidateStartedAt,
               now - candidateStart >= configuration.minimumSpeechDuration {
                hasConfirmedSpeech = true
                return .speechStarted
            }
        } else if hasConfirmedSpeech,
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.silenceDurationToFinish {
            reset()
            return .speechEnded
        } else if !hasConfirmedSpeech,
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.interruptedSpeechTolerance {
            speechCandidateStartedAt = nil
            self.lastSpeechDetectedAt = nil
        }

        return nil
    }

    private static func clampedSpeechThreshold(_ threshold: Float) -> Float {
        min(
            max(threshold, speechThresholdRange.lowerBound),
            speechThresholdRange.upperBound
        )
    }
}
