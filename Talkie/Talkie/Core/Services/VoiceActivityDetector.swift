//
//  VoiceActivityDetector.swift
//  Talkie
//

@preconcurrency import AVFoundation
import Accelerate
import Foundation

final class VoiceActivityDetector: @unchecked Sendable {
    static let speechThresholdRange = VoiceActivityGate.speechThresholdRange
    typealias Configuration = VoiceActivityGate.Configuration

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
    var onInputLevelChanged: (@Sendable (Float) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let stateLock = NSLock()
    private var gate: VoiceActivityGate

    private var isRunning = false
    private var isTapInstalled = false
    private var isSpeakerEnabled = false
    private var smoothedInputLevel: Float?
    private var lastPublishedLevelAt: TimeInterval = 0

    init() {
        gate = VoiceActivityGate()
    }

    init(configuration: Configuration) {
        gate = VoiceActivityGate(configuration: configuration)
    }

    var speechThreshold: Float {
        stateLock.lock()
        defer { stateLock.unlock() }
        return gate.speechThreshold
    }

    static func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func updateSpeechThreshold(_ threshold: Float) {
        stateLock.lock()
        gate.updateSpeechThreshold(threshold)
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
            self.process(rawDecibels: Self.decibels(from: buffer))
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

    private func process(rawDecibels: Float) {
        let now = ProcessInfo.processInfo.systemUptime
        var event: VoiceActivityGate.Event?
        var publishedLevel: Float?

        stateLock.lock()

        guard isRunning else {
            stateLock.unlock()
            return
        }

        let inputLevel = smoothed(decibels: rawDecibels)
        event = gate.process(decibels: inputLevel, at: now)

        if now - lastPublishedLevelAt >= 0.1 {
            lastPublishedLevelAt = now
            publishedLevel = inputLevel
        }

        stateLock.unlock()

        if let publishedLevel {
            onInputLevelChanged?(publishedLevel)
        }

        switch event {
        case .speechStarted:
            onSpeechStarted?()
        case .speechEnded:
            onSpeechEnded?()
        case nil:
            break
        }
    }

    private func smoothed(decibels: Float) -> Float {
        let clampedLevel = min(max(decibels, -80), 0)

        guard let previousLevel = smoothedInputLevel else {
            smoothedInputLevel = clampedLevel
            return clampedLevel
        }

        let nextLevel = previousLevel + 0.3 * (clampedLevel - previousLevel)
        smoothedInputLevel = nextLevel
        return nextLevel
    }

    private func resetDetectionState(isRunning: Bool) {
        stateLock.lock()
        self.isRunning = isRunning
        gate.reset()
        smoothedInputLevel = nil
        lastPublishedLevelAt = 0
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
}
