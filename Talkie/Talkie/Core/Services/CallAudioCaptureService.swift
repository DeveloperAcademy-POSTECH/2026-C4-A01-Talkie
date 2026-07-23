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
        // 첫 상대방 음원을 준비하는 짧은 구간에 실제 주변 소음 기준을 선행 학습합니다.
        voiceActivityDetector.beginAmbientCalibration()

        return didStartRecording
    }

    func endAmbientCalibration() {
        voiceActivityDetector.endAmbientCalibration()
    }

    /// 현재 사용자 턴의 적응형 VAD를 시작하고, callback 검증에 사용할 턴 ID를 반환합니다.
    func beginVoiceDetection() throws -> UUID {
        guard inputFormat != nil, audioEngine.isRunning else {
            throw CaptureError.audioInputUnavailable
        }
        return voiceActivityDetector.beginListening()
    }

    func stopVoiceDetection() {
        voiceActivityDetector.pauseListening()
    }

    /// 백그라운드 전환이나 일시적인 오디오 interruption 뒤에도 기존 input tap과
    /// 녹음 writer를 버리지 않고 마이크 엔진만 다시 활성화합니다.
    /// 새 capture session을 만들지 않으므로 진행 중인 녹음 파일도 끊기지 않습니다.
    func resumeIfNeeded(speakerEnabled: Bool) throws {
        guard inputFormat != nil, isTapInstalled else {
            throw CaptureError.audioInputUnavailable
        }

        try FakeCallAudioSession.activate(speakerEnabled: speakerEnabled)
        guard !audioEngine.isRunning else { return }

        audioEngine.prepare()
        try audioEngine.start()
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
        voiceActivityDetector.reset()
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
