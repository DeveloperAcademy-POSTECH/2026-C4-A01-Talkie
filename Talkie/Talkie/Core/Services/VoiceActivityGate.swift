import Foundation

/// 마이크 입력의 절대 크기가 아니라, 현재 주변 소음과의 차이로 발화를 판정하는 상태 기계입니다.
///
/// 이 타입은 AVAudioEngine이나 비동기 Task를 알지 못합니다. 입력은 `dBFS + 버퍼 길이`뿐이므로
/// 실제 시간을 기다리지 않고 합성 오디오 시퀀스로 규칙을 검증할 수 있습니다.
///
/// 핵심 규칙은 다음과 같습니다.
/// - 주변 소음보다 충분히 큰 입력이 0.2초 이어지면 발화 시작
/// - 발화 중 낮은 입력이 0.6초 이어지면 발화 종료
/// - 발화 전에는 연속 무음이 3초 누적될 때만 무응답 처리
/// - 짧은 소리 후보도 무음 누적을 0으로 되돌리므로, 3초는 항상 "마지막 소리 이후"부터 다시 계산
nonisolated struct VoiceActivityGate: Sendable {
    struct Configuration: Sendable {
        /// 주변 소음보다 이만큼 큰 입력을 발화 후보로 봅니다.
        var speechStartMarginDB: Float = 10
        /// 발화 종료에는 더 낮은 문턱을 사용해 경계에서 상태가 빠르게 흔들리는 것을 막습니다.
        var speechEndMarginDB: Float = 6
        var minimumSpeechDuration: TimeInterval = 0.2
        var silenceDurationToFinish: TimeInterval = 0.6
        var noResponseSilenceDuration: TimeInterval = 3

        /// 첫 오디오 프레임이 곧바로 사용자 목소리여도 감지를 시작할 수 있게 하는 초기 추정값입니다.
        /// 이후에는 실제 입력으로 계속 갱신되므로 고정 발화 기준으로 사용되지는 않습니다.
        var initialNoiseFloorDBFS: Float = -55
        var minimumLevelDBFS: Float = -80
        var maximumLevelDBFS: Float = 0

        /// 소음이 작아졌을 때는 빠르게, 커졌을 때는 천천히 기준선을 움직입니다.
        /// 목소리 한 번이 주변 소음 기준을 갑자기 끌어올리는 것을 막기 위한 비대칭 필터입니다.
        var noiseFloorDownwardSmoothing: Float = 0.2
        var noiseFloorUpwardSmoothing: Float = 0.02
        /// 상대방 음원이 시작되기 전의 짧은 보정 구간에서는 실제 환경 소음에 더 빨리 수렴합니다.
        var ambientCalibrationUpwardSmoothing: Float = 0.12
    }

    enum Event: Equatable, Sendable {
        case speechStarted
        case speechEnded
        case continuousSilenceReached
    }

    private let configuration: Configuration
    private var noiseFloorDBFS: Float
    private var speechCandidateDuration: TimeInterval = 0
    private var speechEndingSilenceDuration: TimeInterval = 0
    private var noResponseSilenceDuration: TimeInterval = 0
    private var hasConfirmedSpeech = false
    private var isTurnFinished = false

    init(configuration: Configuration = .init()) {
        self.configuration = configuration
        noiseFloorDBFS = configuration.initialNoiseFloorDBFS
    }

    /// 새 사용자 턴을 시작합니다. 통화 중 이미 학습한 주변 소음값은 유지합니다.
    mutating func resetTurn() {
        speechCandidateDuration = 0
        speechEndingSilenceDuration = 0
        noResponseSilenceDuration = 0
        hasConfirmedSpeech = false
        isTurnFinished = false
    }

    /// 통화 종료 시 턴 상태와 학습된 주변 소음값을 모두 초기화합니다.
    mutating func resetAll() {
        noiseFloorDBFS = configuration.initialNoiseFloorDBFS
        resetTurn()
    }

    /// 상대방 음원이 시작되기 전, 마이크에 실제 주변 소음만 들어오는 구간에서 기준선을 준비합니다.
    mutating func observeAmbient(levelDBFS: Float) {
        updateNoiseFloor(
            with: clamped(levelDBFS),
            upwardSmoothing: configuration.ambientCalibrationUpwardSmoothing
        )
    }

    mutating func process(levelDBFS: Float, duration: TimeInterval) -> Event? {
        guard duration.isFinite, duration > 0, !isTurnFinished else { return nil }

        let level = clamped(levelDBFS)
        if hasConfirmedSpeech {
            return processConfirmedSpeech(levelDBFS: level, duration: duration)
        }

        let speechStartThreshold = noiseFloorDBFS + configuration.speechStartMarginDB
        if level >= speechStartThreshold {
            // 발화로 확정되기 전의 짧은 충격음도 "소리가 있었음"에는 해당합니다.
            // 따라서 무응답 시간은 즉시 0으로 되돌리고, 소리가 끝난 뒤부터 다시 셉니다.
            noResponseSilenceDuration = 0
            speechCandidateDuration += duration

            if speechCandidateDuration + 0.000_001 >= configuration.minimumSpeechDuration {
                hasConfirmedSpeech = true
                speechEndingSilenceDuration = 0
                return .speechStarted
            }
            return nil
        }

        // 후보가 발화로 확정되기 전에 끝났다면 기침/충격음으로 보고 후보만 버립니다.
        // 현재의 낮은 버퍼부터 새로운 연속 무음 구간이 시작됩니다.
        speechCandidateDuration = 0
        noResponseSilenceDuration += duration
        updateNoiseFloor(
            with: level,
            upwardSmoothing: configuration.noiseFloorUpwardSmoothing
        )

        if noResponseSilenceDuration + 0.000_001 >= configuration.noResponseSilenceDuration {
            isTurnFinished = true
            return .continuousSilenceReached
        }
        return nil
    }

    private mutating func processConfirmedSpeech(
        levelDBFS: Float,
        duration: TimeInterval
    ) -> Event? {
        let speechEndThreshold = noiseFloorDBFS + configuration.speechEndMarginDB
        if levelDBFS < speechEndThreshold {
            speechEndingSilenceDuration += duration
        } else {
            speechEndingSilenceDuration = 0
        }

        if speechEndingSilenceDuration + 0.000_001 >= configuration.silenceDurationToFinish {
            isTurnFinished = true
            return .speechEnded
        }
        return nil
    }

    private mutating func updateNoiseFloor(
        with levelDBFS: Float,
        upwardSmoothing: Float
    ) {
        let smoothing = levelDBFS < noiseFloorDBFS
            ? configuration.noiseFloorDownwardSmoothing
            : upwardSmoothing
        noiseFloorDBFS += smoothing * (levelDBFS - noiseFloorDBFS)
        noiseFloorDBFS = clamped(noiseFloorDBFS)
    }

    private func clamped(_ levelDBFS: Float) -> Float {
        guard levelDBFS.isFinite else { return configuration.minimumLevelDBFS }
        return min(
            max(levelDBFS, configuration.minimumLevelDBFS),
            configuration.maximumLevelDBFS
        )
    }
}
