//
//  CallRecordingWriter.swift
//  Talkie
//

@preconcurrency import AVFoundation
import Foundation

/// 입력 탭에서 받은 PCM 버퍼를 하나의 Core Audio 파일로 순차 기록합니다.
/// 오디오 콜백과 화면 종료가 서로 다른 실행 문맥에서 올 수 있어 모든 파일 상태는 lock으로 보호합니다.
nonisolated final class CallRecordingWriter: @unchecked Sendable {
    enum WriterError: LocalizedError {
        case unsupportedInputFormat

        var errorDescription: String? {
            switch self {
            case .unsupportedInputFormat:
                "통화 녹음에 사용할 수 없는 오디오 형식입니다."
            }
        }
    }

    private let fileStore: CallRecordingFileStore
    private let stateLock = NSLock()

    private var audioFile: AVAudioFile?
    private var fileName: String?
    private var createdAt: Date?
    private var sampleRate: Double = 0
    private var writtenFrameCount: AVAudioFramePosition = 0
    private var writeFailed = false

    init(fileStore: CallRecordingFileStore = CallRecordingFileStore()) {
        self.fileStore = fileStore
    }

    func start(inputFormat: AVAudioFormat) throws {
        cancel()

        guard inputFormat.sampleRate > 0,
              inputFormat.channelCount > 0,
              inputFormat.commonFormat == .pcmFormatFloat32,
              !inputFormat.isInterleaved else {
            throw WriterError.unsupportedInputFormat
        }

        let fileName = fileStore.makeFileName()
        let fileURL = try fileStore.url(for: fileName)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: Int(inputFormat.channelCount),
            AVEncoderBitRateKey: 64_000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        // 마이크 tap은 Float32 PCM을 전달하지만 파일은 AAC로 인코딩합니다.
        // client format을 입력 형식과 같게 지정하면 AVAudioFile이 쓰기 과정에서
        // 변환하며, 긴 녹음도 CloudKit CKAsset에 올릴 수 있는 크기로 유지됩니다.
        let audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: settings,
            commonFormat: inputFormat.commonFormat,
            interleaved: inputFormat.isInterleaved
        )

        stateLock.lock()
        self.audioFile = audioFile
        self.fileName = fileName
        createdAt = Date()
        sampleRate = inputFormat.sampleRate
        writtenFrameCount = 0
        writeFailed = false
        stateLock.unlock()
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        guard buffer.frameLength > 0 else { return }

        stateLock.lock()
        defer { stateLock.unlock() }
        guard let audioFile, !writeFailed else { return }

        do {
            try audioFile.write(from: buffer)
            writtenFrameCount += AVAudioFramePosition(buffer.frameLength)
        } catch {
            writeFailed = true
        }
    }

    func finish() -> CompletedCallRecording? {
        stateLock.lock()
        let fileName = fileName
        let createdAt = createdAt
        let sampleRate = sampleRate
        let writtenFrameCount = writtenFrameCount
        let writeFailed = writeFailed
        clearStateLocked()
        stateLock.unlock()

        guard let fileName else { return nil }
        guard !writeFailed, writtenFrameCount > 0, sampleRate > 0 else {
            try? fileStore.delete(fileName: fileName)
            return nil
        }

        guard let fileSize = try? fileStore.fileSize(fileName: fileName) else {
            try? fileStore.delete(fileName: fileName)
            return nil
        }

        return CompletedCallRecording(
            fileName: fileName,
            duration: Double(writtenFrameCount) / sampleRate,
            fileSize: fileSize,
            createdAt: createdAt ?? Date()
        )
    }

    func cancel() {
        stateLock.lock()
        let fileName = fileName
        clearStateLocked()
        stateLock.unlock()

        if let fileName {
            try? fileStore.delete(fileName: fileName)
        }
    }

    private func clearStateLocked() {
        audioFile = nil
        fileName = nil
        createdAt = nil
        sampleRate = 0
        writtenFrameCount = 0
        writeFailed = false
    }
}
