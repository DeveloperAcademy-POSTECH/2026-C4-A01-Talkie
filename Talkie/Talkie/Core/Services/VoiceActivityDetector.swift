//
//  VoiceActivityDetector.swift
//  Talkie
//


@preconcurrency import AVFoundation
import Accelerate
import Foundation

final class VoiceActivityDetector: @unchecked Sendable {
    static let speechThresholdRange: ClosedRange<Float> = -60 ... -20

    struct Configuration: Sendable {
        var speechThreshold: Float = -35
        var minimumSpeechDuration: TimeInterval = 0.2
        var silenceDurationToFinish: TimeInterval = 0.7
        var interruptedSpeechTolerance: TimeInterval = 0.12
    }

    enum DetectorError: LocalizedError {
        case audioInputUnavailable

        var errorDescription: String? {
            switch self {
            case .audioInputUnavailable:
                "사용할 수 있는 마이크 입력이 없습니다."
            }
        }
    }

    var onSpeechStarted: (@Sendable () -> Void)?
    var onSpeechEnded: (@Sendable () -> Void)?

    private let audioEngine = AVAudioEngine()
    private var configuration: Configuration
    private let stateLock = NSLock()

    private var isRunning = false
    private var isTapInstalled = false
    private var isSpeakerEnabled = false
    private var speechCandidateStartedAt: TimeInterval?
    private var lastSpeechDetectedAt: TimeInterval?
    private var hasConfirmedSpeech = false

    init() {
        configuration = Configuration()
    }

    init(configuration: Configuration) {
        var configuration = configuration
        configuration.speechThreshold = Self.clampedSpeechThreshold(
            configuration.speechThreshold
        )
        self.configuration = configuration
    }

    var speechThreshold: Float {
        stateLock.lock()
        defer { stateLock.unlock() }
        return configuration.speechThreshold
    }

    static func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func updateSpeechThreshold(_ threshold: Float) {
        stateLock.lock()
        configuration.speechThreshold = Self.clampedSpeechThreshold(threshold)

        if !hasConfirmedSpeech {
            speechCandidateStartedAt = nil
            lastSpeechDetectedAt = nil
        }

        stateLock.unlock()
    }

    func setSpeakerEnabled(_ enabled: Bool) {
        stateLock.lock()
        isSpeakerEnabled = enabled
        stateLock.unlock()
    }

    func start() throws {
        stop()

        stateLock.lock()
        let speakerEnabled = isSpeakerEnabled
        stateLock.unlock()
        try FakeCallAudioSession.activate(speakerEnabled: speakerEnabled)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw DetectorError.audioInputUnavailable
        }

        resetDetectionState(isRunning: true)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: format
        ) { [weak self] buffer, _ in
            guard let self else { return }
            self.process(decibels: Self.decibels(from: buffer))
        }
        isTapInstalled = true

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            isTapInstalled = false
            resetDetectionState(isRunning: false)
            throw error
        }
    }

    func stop() {
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        resetDetectionState(isRunning: false)
    }

    private func process(decibels: Float) {
        let now = ProcessInfo.processInfo.systemUptime
        var shouldNotifySpeechStarted = false
        var shouldNotifySpeechEnded = false

        stateLock.lock()

        guard isRunning else {
            stateLock.unlock()
            return
        }

        if decibels >= configuration.speechThreshold {
            if speechCandidateStartedAt == nil {
                speechCandidateStartedAt = now
            }

            lastSpeechDetectedAt = now

            if !hasConfirmedSpeech,
               let candidateStart = speechCandidateStartedAt,
               now - candidateStart >= configuration.minimumSpeechDuration {
                hasConfirmedSpeech = true
                shouldNotifySpeechStarted = true
            }
        } else if hasConfirmedSpeech,
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.silenceDurationToFinish {
            hasConfirmedSpeech = false
            speechCandidateStartedAt = nil
            self.lastSpeechDetectedAt = nil
            shouldNotifySpeechEnded = true
        } else if !hasConfirmedSpeech,
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.interruptedSpeechTolerance {
            speechCandidateStartedAt = nil
            self.lastSpeechDetectedAt = nil
        }

        stateLock.unlock()

        if shouldNotifySpeechStarted {
            onSpeechStarted?()
        }

        if shouldNotifySpeechEnded {
            onSpeechEnded?()
        }
    }

    private func resetDetectionState(isRunning: Bool) {
        stateLock.lock()
        self.isRunning = isRunning
        speechCandidateStartedAt = nil
        lastSpeechDetectedAt = nil
        hasConfirmedSpeech = false
        stateLock.unlock()
    }

    private static func decibels(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?.pointee else {
            return -160
        }

        let frameCount = vDSP_Length(buffer.frameLength)
        guard frameCount > 0 else { return -160 }

        var meanSquare: Float = 0
        vDSP_measqv(channelData, 1, &meanSquare, frameCount)

        let rootMeanSquare = sqrt(meanSquare)
        return 20 * log10(max(rootMeanSquare, 0.000_000_1))
    }

    private static func clampedSpeechThreshold(_ threshold: Float) -> Float {
        min(
            max(threshold, speechThresholdRange.lowerBound),
            speechThresholdRange.upperBound
        )
    }
}
