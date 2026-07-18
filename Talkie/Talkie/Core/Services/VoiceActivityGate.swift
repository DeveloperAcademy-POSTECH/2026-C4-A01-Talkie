import Foundation

/// Apple SpeechDetector의 프레임별 Bool 결과를 안정적인 발화 시작/종료 이벤트로 바꾸는 상태 기계.
///
/// SpeechDetector가 짧게 `true/false`를 흔들어도 화면이 즉시 전환되지 않도록 세 시간 조건을 둔다.
/// - `minimumSpeechDuration`: 실제 발화로 확정하기 전에 필요한 연속 음성 시간
/// - `silenceDurationToFinish`: 발화 종료로 확정하기 전에 필요한 연속 무음 시간
/// - `interruptedSpeechTolerance`: 아직 확정되지 않은 짧은 후보 발화가 끊겼다고 보는 시간
///
/// 오디오 프레임이나 dB 값을 직접 다루지 않는 순수 값 타입이라 합성 시간 입력으로 테스트할 수 있다.
nonisolated struct VoiceActivityGate: Sendable {
    struct Configuration: Sendable {
        var minimumSpeechDuration: TimeInterval = 0.2
        var silenceDurationToFinish: TimeInterval = 0.5
        var interruptedSpeechTolerance: TimeInterval = 0.12
    }

    enum Event: Equatable, Sendable {
        case speechStarted
        case speechEnded
    }

    private let configuration: Configuration
    // true가 처음 관찰된 시각. minimumSpeechDuration을 넘기기 전까지는 후보일 뿐이다.
    private var speechCandidateStartedAt: TimeInterval?
    // 가장 최근 true 시각. 확정 발화 뒤 silenceDurationToFinish 계산의 기준이 된다.
    private var lastSpeechDetectedAt: TimeInterval?
    private var hasConfirmedSpeech = false

    init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    mutating func reset() {
        speechCandidateStartedAt = nil
        lastSpeechDetectedAt = nil
        hasConfirmedSpeech = false
    }

    mutating func process(isSpeechDetected: Bool, at now: TimeInterval) -> Event? {
        if isSpeechDetected {
            if speechCandidateStartedAt == nil {
                speechCandidateStartedAt = now
            }
            lastSpeechDetectedAt = now

            // 짧은 기침이나 잡음 한 프레임은 무시하고 연속 음성이 기준 시간을 넘을 때 한 번만 시작한다.
            if !hasConfirmedSpeech,
               let startedAt = speechCandidateStartedAt,
               now - startedAt >= configuration.minimumSpeechDuration {
                hasConfirmedSpeech = true
                return .speechStarted
            }
        } else if hasConfirmedSpeech,
                  // 확정된 발화는 false 한 번으로 끝내지 않는다. 마지막 음성 이후 충분한 무음을 기다린다.
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.silenceDurationToFinish {
            reset()
            return .speechEnded
        } else if !hasConfirmedSpeech,
                  // 확정 전에 후보가 끊기면 상태를 비워 다음 true를 새 후보로 시작한다.
                  let lastSpeechDetectedAt,
                  now - lastSpeechDetectedAt >= configuration.interruptedSpeechTolerance {
            speechCandidateStartedAt = nil
            self.lastSpeechDetectedAt = nil
        }
        return nil
    }
}
