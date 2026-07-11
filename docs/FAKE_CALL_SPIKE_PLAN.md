# FakeCall 기술 스파이크 계획

작성일: 2026-07-11
대상 프로젝트: `project/2026-C4-A01-Talkie`
담당: BK
관련 담당: 케빈 - 저장 모델 / SwiftData 구조

## 구현 진행 상태 - 2026-07-11

계획서의 Step 1~5를 첫 코드 스파이크로 구현했다.

- [x] 테스트 진입점 -> 수신 화면 -> 통화 화면 전환
- [x] mock profile과 문장 3개
- [x] 오디오 파일이 없을 때 한국어 TTS 재생
- [x] `AVAudioEngine` 기반 VAD와 말끝 감지 코드 구현
- [x] 말끝 후 0.5초 대기, 무발화 8초 fallback
- [x] 마이크 권한 거부 시 시간 기반 자동 진행
- [x] `.m4a`가 있으면 우선 재생하고 없으면 TTS로 대체하는 구조
- [x] iPhone 17 Pro / iOS 26.5 Simulator 수신·통화 화면 검증
- [x] 마이크 권한 허용·거부 상태에서 3문장 fallback 후 통화 유지 검증
- [ ] 실제 발화 -> 말끝 -> 0.5초 -> 다음 문장 전환은 이번 검증에서 제외하고 iPhone 실기기 수동 테스트로 진행

주요 구현 위치:

```text
Talkie/Talkie/Features/FakeCall/
Talkie/Talkie/Core/Services/
```

Debug 재현 인자:

```text
--fake-call-auto-start   # 수신 화면까지 자동 진입
--fake-call-auto-accept  # 자동 수신 후 통화 루프 시작
```

현재 시뮬레이터 검증은 무발화 fallback을 포함한다. 실제 발화 입력 테스트는 이번 범위에서 제외했으며, 사용자가 말한 뒤 0.5초 후 다음 문장으로 넘어가는 흐름과 VAD 임계값은 iPhone 실기기 및 실제 환경 소음으로 수동 확인한다.

## 1. 목적

이번 스파이크의 목적은 C4 Talkie의 핵심 경험인 `가상 통화`가 실제로 가능한지 빠르게 검증하는 것이다.

최종 목표는 실제 전화처럼 보이는 수신 화면에서 전화를 받고, 상대방의 녹음 문장이 재생된 뒤, 사용자가 대답을 멈추면 약 0.5초 후 다음 문장이 재생되는 흐름을 만드는 것이다.

이번 작업은 저장 모델 구현이 아니라 `통화 경험 루프` 검증이다. 케빈이 저장 모델을 붙이기 전까지는 mock script와 TTS 또는 임시 오디오를 사용한다.

## 2. 성공 기준

첫 스파이크는 아래 루프가 실제 기기 또는 시뮬레이터에서 동작하면 성공으로 본다.

```text
Home 또는 테스트 진입점
  -> 실제 전화처럼 보이는 수신 화면
  -> 수신
  -> 통화 화면
  -> 첫 문장 오디오 재생
  -> 사용자가 대답
  -> 말이 끝난 뒤 0.5초 대기
  -> 다음 문장 오디오 재생
  -> 위 흐름 반복
```

완성도 기준:

- 수신 화면은 앱 화면이 아니라 iPhone 전화 화면처럼 보여야 한다.
- 통화 화면에는 C4 설명, 안전 기능 문구, 브랜딩을 노출하지 않는다.
- 사용자의 발화 내용은 이해하지 않아도 된다.
- 사용자가 말했는지, 말이 끝났는지만 감지한다.
- 마지막 문장 이후에는 통화 화면을 유지하거나 종료 버튼으로 종료할 수 있다.

## 3. 기술 선택

### 3.1 1차 스파이크: Voice Activity Detection

처음에는 `Speech Recognition`이 아니라 `Voice Activity Detection`으로 시작한다.

이유:

- 필요한 것은 사용자가 무엇을 말했는지가 아니라 말이 끝났는지다.
- 음성을 텍스트로 바꾸지 않으므로 개인정보 부담이 작다.
- 마이크 입력의 볼륨/레벨 기반으로 빠르게 실험할 수 있다.
- 소음 환경에서 실패하더라도 수동 다음 문장 또는 시간 기반 fallback을 붙이기 쉽다.

필요 기술:

- `AVAudioEngine`
- `AVAudioSession`
- 마이크 입력 레벨 측정
- silence timeout
- fallback timer

권한:

- `NSMicrophoneUsageDescription` 필요
- `NSSpeechRecognitionUsageDescription`은 1차 스파이크에서는 필요 없음

### 3.2 오디오 재생 방식

1차에서는 별도 오디오 파일을 준비하지 않아도 된다.

단계별 접근:

| 단계 | 방식 | 목적 |
| --- | --- | --- |
| 1차 | `AVSpeechSynthesizer` TTS | 오디오 파일 없이 통화 루프 검증 |
| 2차 | 앱 내부 문장별 녹음 `.m4a` | 실제 목표 구조에 가까운 검증 |
| 3차 | 케빈 저장 모델 연결 | 저장된 script/audio metadata 기반 재생 |

TTS는 최종 품질을 위한 것이 아니라, 통화 흐름과 말끝 감지 루프를 빠르게 확인하기 위한 임시 장치다.

## 4. Speech Recognition은 언제 쓰나?

`Speech Recognition`은 후속 단계에서 검토한다.

필요해지는 경우:

- 사용자가 "위치 보내"라고 말하면 위치 공유로 이동
- 사용자가 "신고"라고 말하면 SOS 경로를 열기
- 사용자의 실제 발화를 텍스트 기록으로 남기기
- 답변 내용에 따라 다른 오디오 분기로 이동

현재 목표는 단순하다.

```text
사용자가 말함
사용자가 멈춤
0.5초 뒤 다음 문장
```

따라서 1차 스파이크에는 VAD가 더 적합하다.

## 5. 케빈 저장 모델과의 접점

BK는 FakeCall 경험을 mock 데이터로 먼저 구현한다. 케빈은 저장 모델을 구현한다. 둘이 만나는 접점은 아래 3개 타입이다.

```swift
struct VirtualCallerProfile: Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var relationship: String
    var imageName: String?
}

struct FakeCallScriptLine: Identifiable, Hashable {
    let id: UUID
    let profileID: UUID
    var order: Int
    var text: String
    var audioClipID: UUID?
}

struct VoiceClipMetadata: Identifiable, Hashable {
    let id: UUID
    let scriptLineID: UUID
    var localFileName: String?
    var duration: TimeInterval
}
```

초기에는 실제 저장소 대신 mock repository를 사용한다.

```swift
protocol FakeCallScriptRepository {
    func activeProfile() async throws -> VirtualCallerProfile
    func scriptLines(for profileID: UUID) async throws -> [FakeCallScriptLine]
    func voiceClip(for lineID: UUID) async throws -> VoiceClipMetadata?
}
```

1차 스파이크에서는 `voiceClip`이 없어도 된다. 오디오 파일이 없으면 TTS로 `text`를 읽는다.

## 6. 권장 파일 구조

현재 프로젝트의 빈 폴더 구조를 살려서 `Features/FakeCall` 아래에 둔다.

```text
Talkie/Talkie/
  Features/
    FakeCall/
      FakeCallEntryView.swift
      IncomingFakeCallView.swift
      ActiveFakeCallView.swift
      FakeCallCoordinator.swift
      FakeCallScriptMock.swift

  Core/
    Services/
      ScriptedAudioPlayer.swift
      VoiceActivityDetector.swift
```

파일 책임:

| 파일 | 책임 |
| --- | --- |
| `FakeCallEntryView` | 스파이크 진입점. 지금은 테스트 버튼만 있어도 됨 |
| `IncomingFakeCallView` | 실제 전화처럼 보이는 수신 화면 |
| `ActiveFakeCallView` | 통화 중 화면, 현재 문장 상태, 종료 |
| `FakeCallCoordinator` | 수신/통화/문장 진행 상태 조정 |
| `FakeCallScriptMock` | 저장 모델 전까지 사용할 mock script |
| `ScriptedAudioPlayer` | TTS 또는 오디오 파일 재생 |
| `VoiceActivityDetector` | 말 시작/말끝 감지 |

## 7. 상태 흐름

```text
idle
  -> incoming(profile)
  -> activeCall(lineIndex: 0)
  -> playingSystemAudio
  -> waitingForUserSpeech
  -> userSpeaking
  -> userSilenceGracePeriod(0.5s)
  -> playingSystemAudio(nextLine)
  -> completed 또는 activeCall 유지
```

`FakeCallCoordinator`는 이 상태를 하나의 흐름으로 관리한다.

권장 enum:

```swift
enum FakeCallPhase: Equatable {
    case idle
    case incoming
    case active
    case playingLine(Int)
    case waitingForUser
    case userSpeaking
    case waitingForNextLine
    case completed
}
```

## 8. Voice Activity Detection 기준값 초안

첫 값은 너무 정교하게 잡지 않는다. 실제 기기에서 조정한다.

```text
speechThreshold: -35 dB 근처에서 시작
adjustableSpeechThreshold: -60~-20 dB, 1 dB 단위
minimumSpeechDuration: 0.2초
silenceDurationToFinish: 0.7초
nextLineDelayAfterSilence: 0.5초
maxWaitForUserSpeech: 8초
```

fallback:

- 사용자가 말하지 않으면 8초 후 다음 문장 재생
- 소음 때문에 계속 speaking으로 잡히면 수동 다음 버튼 제공
- 마이크 권한 거부 시 시간 기반 자동 진행으로 대체
- 실제 기기 테스트 중 통화 화면 슬라이더로 임계값을 조정하고 표시된 dB를 기록
- 기본 출력은 수화부이며, 스피커 버튼을 켰을 때만 스피커 출력으로 전환
- 스피커 전환 전 통화용 `.playAndRecord + voiceChat` 세션을 활성화해 통화 시작 직후에도 라우팅이 동작
- 스피커를 끄면 `.none` 오버라이드로 돌아가 수화부를 포함한 시스템 기본 통화 경로를 사용
- 수신·통화 화면을 포함한 앱 전체 방향은 세로로 고정
- 즉시 가상통화 수신 화면에서는 앱 번들의 `iphone_bell.caf`를 `AVAudioPlayer`로 직접 반복 재생
- 직접 재생은 알림 권한과 무관하며, 통화 수신·거절 시 즉시 정지
- 예약·백그라운드 호출은 추후 로컬 알림에서 같은 CAF 파일을 커스텀 알림음으로 사용
- 원본 `iphone_bell.mp3`는 보존하고, 앱에는 30초 미만 IMA4/CAF 변환본만 포함
- 앱 내 직접 재생은 미디어 음량을 사용하며, 예약 호출의 알림음은 시스템 알림·사운드 설정을 따름
- 예약 호출의 첫 알림 권한 요청은 수신 화면 진입 전에 마쳐 실제 전화 화면을 가리지 않음

## 9. 권한 요청 문구

마이크 권한은 가상 통화가 처음 시작되기 직전에 요청한다.

권장 문구:

```text
가상 통화 중 사용자가 말한 뒤 다음 문장으로 자연스럽게 넘어가기 위해 마이크를 사용합니다. 음성은 이 기능을 위해 기기 안에서만 처리됩니다.
```

원칙:

- 앱 첫 실행에서 모든 권한을 한꺼번에 요청하지 않는다.
- Speech Recognition 권한은 1차 스파이크에서 요청하지 않는다.
- 마이크 권한이 거부되어도 가상 통화 자체는 시간 기반으로 진행되어야 한다.

## 10. 구현 순서

### Step 1. 화면 루프

- `FakeCallEntryView`에서 테스트 버튼 제공
- 버튼을 누르면 `IncomingFakeCallView` 표시
- 수신하면 `ActiveFakeCallView` 표시

완료 기준:

- 실제 전화 수신 화면처럼 보이는 전체 화면이 뜬다.
- 수신/거절 버튼이 있다.
- 수신하면 통화 화면으로 간다.

### Step 2. TTS 문장 재생

- mock script 3문장 준비
- 수신 후 첫 문장을 TTS로 재생
- 재생 완료 후 사용자 발화 대기 상태로 전환

완료 기준:

- 통화 화면에서 문장이 순서대로 재생될 준비가 된다.

### Step 3. VAD 붙이기

- 마이크 권한 요청
- 말 시작 감지
- 말끝 감지
- 말끝 후 0.5초 뒤 다음 문장 재생

완료 기준:

- 사용자가 말하고 멈추면 다음 문장으로 넘어간다.

### Step 4. fallback

- 마이크 권한 거부 시 자동 시간 진행
- 발화 감지 실패 시 수동 다음 문장 버튼
- 마지막 문장 이후 통화 유지 또는 종료

완료 기준:

- 권한/소음/무응답 상황에서도 앱이 멈추지 않는다.

### Step 5. 녹음 파일 재생으로 교체

- 문장별 `.m4a` 녹음 파일이 있으면 파일 재생
- 파일이 없으면 TTS fallback

완료 기준:

- 케빈 저장 모델과 연결하기 전에도 오디오 파일 기반 재생 구조가 준비된다.

## 11. 이번 스파이크에서 하지 않을 것

- 실제 112 신고
- 위치 공유
- iCloud / CloudKit
- SwiftData 저장
- Speech Recognition
- 의미 기반 AI 대화
- CallKit / VoIP
- 실제 iPhone 시스템 전화 화면 호출

이번 스파이크는 SwiftUI로 전화처럼 보이는 화면을 만들고, 앱 내부 오디오/마이크 루프를 검증하는 데 집중한다.

## 12. 회의에서 합의해야 할 것

BK와 케빈이 먼저 맞출 질문:

1. 저장 모델의 script line 단위는 문장 하나가 맞는가?
2. 오디오가 없을 때 TTS fallback을 허용할 것인가?
3. 마이크 권한 거부 시 시간 기반 진행을 기본 fallback으로 둘 것인가?
4. 통화 중 수동 다음 문장 버튼을 화면에 숨길 것인가, 디버그에서만 보일 것인가?
5. 마지막 문장 이후 통화를 유지할 것인가, 자동 종료할 것인가?

## 13. 첫 PR 기준

첫 PR은 완성 기능이 아니라 기술 검증으로 낸다.

PR 제목 예시:

```text
feat: add FakeCall scripted conversation spike
```

PR 포함:

- FakeCall 화면 루프
- mock script
- TTS 기반 문장 재생
- VAD 기반 말끝 감지
- fallback 동작

PR 제외:

- 저장 모델
- CloudKit
- 112/SOS
- 위치 공유

## 14. 최종 판단

이 스파이크가 성공하면 C4의 핵심 재미가 처음으로 살아난다. 이후 케빈의 저장 모델을 붙이면 사용자가 직접 녹음한 문장들을 실제 가상 통화 안에서 재생할 수 있다.

따라서 다음 개발 순서는 `FakeCall 통화 루프 스파이크 -> 문장별 녹음 파일 재생 -> 케빈 저장 모델 연결`이 적절하다.
