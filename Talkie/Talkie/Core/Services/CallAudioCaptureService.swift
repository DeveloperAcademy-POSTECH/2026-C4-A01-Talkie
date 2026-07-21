//
//  CallAudioCaptureService.swift
//  Talkie
//

@preconcurrency import AVFoundation
import Foundation

/// 가상 통화에서 사용하는 마이크 입력의 단일 소유자입니다.
///
/// AVAudioNode는 bus마다 하나의 tap만 허용합니다. 이 서비스가 입력 tap을 한 번만 설치한 뒤
/// 같은 PCM 버퍼를 녹음 writer와 발화 감지기에 전달해 두 기능이 서로 tap을 빼앗지 않게 합니다.
nonisolated final class CallAudioCaptureService: @unchecked Sendable {
    enum CaptureError: LocalizedError {
        case audioInputUnavailable

        var errorDescription: String? {
            "사용할 수 있는 마이크 입력이 없습니다."
        }
    }

    private let audioEngine = AVAudioEngine()
    private let voiceActivityDetector: VoiceActivityDetector
    private let recordingWriter: CallRecordingWriter

    private var inputFormat: AVAudioFormat?
    private var isTapInstalled = false

    init(
        voiceActivityDetector: VoiceActivityDetector,
        recordingWriter: CallRecordingWriter = CallRecordingWriter()
    ) {
        self.voiceActivityDetector = voiceActivityDetector
        self.recordingWriter = recordingWriter
    }

    @discardableResult
    func start(speakerEnabled: Bool, recordsAudio: Bool) throws -> Bool {
        cancel()
        try FakeCallAudioSession.activate(speakerEnabled: speakerEnabled)

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw CaptureError.audioInputUnavailable
        }

        var didStartRecording = false
        if recordsAudio {
            do {
                try recordingWriter.start(inputFormat: inputFormat)
                didStartRecording = true
            } catch {
                // 녹음 파일 생성 실패가 가상 통화와 발화 감지까지 중단시키지 않게 분리합니다.
                recordingWriter.cancel()
            }
        }

        self.inputFormat = inputFormat
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: inputFormat
        ) { [weak self] buffer, _ in
            guard let self else { return }
            recordingWriter.append(buffer)
            voiceActivityDetector.process(buffer: buffer)
        }
        isTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            removeInputTapIfNeeded()
            recordingWriter.cancel()
            self.inputFormat = nil
            throw error
        }

        return didStartRecording
    }

    func startVoiceDetection() throws {
        guard let inputFormat, audioEngine.isRunning else {
            throw CaptureError.audioInputUnavailable
        }
        try voiceActivityDetector.start(inputFormat: inputFormat)
    }

    func stopVoiceDetection() {
        voiceActivityDetector.stop()
    }

    func finish() -> CompletedCallRecording? {
        stopAudioInput()
        return recordingWriter.finish()
    }

    func cancel() {
        stopAudioInput()
        recordingWriter.cancel()
    }

    private func stopAudioInput() {
        voiceActivityDetector.stop()
        removeInputTapIfNeeded()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        inputFormat = nil
    }

    private func removeInputTapIfNeeded() {
        guard isTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isTapInstalled = false
    }
}
