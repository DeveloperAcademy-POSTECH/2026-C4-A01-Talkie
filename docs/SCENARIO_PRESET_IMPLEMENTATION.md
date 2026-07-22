# 시나리오 프리셋 구현

관련 이슈: #54  
브랜치: `feat/#54-3Presets`

## 확정 요구사항

- 앱 기본 프리셋은 Grace, Kaelyn, Kevin 세 개다.
- 목록 표시 순서는 Grace, Kaelyn, Kevin이다.
- 표시 제목은 `Grace와의 통화`, `Kaelyn과의 통화`, `Kevin과의 통화`다.
- 최초 기본 선택은 Kevin이다.
- 프리셋은 수정, 삭제, 재녹음과 iCloud 동기화 대상이 아니다.
- 프리셋 상세 화면에서는 문장별 재생과 전체 재생만 제공한다.
- 통화에 사용할 프리셋은 Phone 탭의 기존 `변경` 화면에서만 선택한다.

## 데이터 경계

```text
PresetScenarioCatalog (Bundle, 읽기 전용)
                ┐
                ├─ ScenarioContent ─ CallScenarioRepository ─ FakeCallCoordinator
                │
Scenario (SwiftData, 사용자 생성)

ScenarioSelectionStore ─ 현재 선택한 preset/custom 참조만 저장
```

### 프리셋

`PresetScenario`와 `PresetScriptLine`은 모두 불변 값 타입이다. 프리셋은 SwiftData에 복사하지 않으며, 오디오 Data 대신 Bundle에서 찾을 수 있는 리소스 이름만 가진다.

### 사용자 시나리오

기존 `Scenario`, `ScriptLine`, `AudioClipMetadata`는 사용자 생성 데이터만 담당한다. 선택을 안정적으로 복원할 수 있도록 `Scenario`와 `ScriptLine`에 UUID를 둔다.

### 선택 상태

`ScenarioSelectionStore`에는 데이터 자체가 아니라 다음 참조만 저장한다.

```text
preset / kevin
custom / <Scenario UUID>
```

저장된 참조가 없거나 사용자 시나리오가 삭제되어 유효하지 않으면 Kevin으로 복구한다.

## 리소스

제작용 WAV 50개를 48 kHz, mono, 약 96 kbps AAC `.m4a`로 변환한다.

```text
Talkie/Talkie/Resources/Presets/
├─ Grace/Grace_01.m4a ... Grace_13.m4a
├─ Kaelyn/Kaelyn_01.m4a ... Kaelyn_13.m4a
└─ Kevin/Kevin_01.m4a ... Kevin_24.m4a
```

검증 명령:

```bash
./Scripts/validate_preset_resources.sh
```

## 데이터 흐름

1. 시나리오 화면은 프리셋 카탈로그와 SwiftData 사용자 시나리오를 `ScenarioContent`로 변환한다.
2. 프리셋 카드는 읽기 전용 상세 화면으로, 사용자 카드는 기존 편집 화면으로 이동한다.
3. Phone 탭의 `변경` 화면이 선택한 `ScenarioReference`를 저장한다.
4. 가상 통화 시작 시 선택된 `ScenarioContent`를 `ScenarioFakeCallScriptRepository`로 복사한다.
5. 프리셋 음원은 Bundle에서, 사용자 녹음은 Documents에서 URL을 해석한다.
6. `FakeCallCoordinator`는 저장 출처와 무관하게 정렬된 문장과 실제 오디오를 재생한다.

## 이전 데이터 처리

기존 버전이 SwiftData에 seed한 프리셋은 앱 시작 시 제거한다. 기존에 선택된 사용자 시나리오는 새 선택 참조로 옮기고, 사용자 시나리오와 사용자 녹음 파일은 유지한다.

`Scenario.presetID`와 `Scenario.isCurrentSelection`은 이전 데이터를 식별하기 위한 임시 호환 필드이며 새 프리셋 저장에는 사용하지 않는다.

## 검증 기준

- 카탈로그 순서와 문장 수가 Grace 13, Kaelyn 13, Kevin 24로 일치한다.
- M4A 50개가 모두 mono AAC 48 kHz이고 앱 Bundle에 포함된다.
- 프리셋 상세 화면에는 편집 및 삭제 메뉴가 없다.
- 개별 재생과 전체 재생이 실제 음원을 사용한다.
- 변경 화면에서 선택한 프리셋이 Phone 카드와 위젯 요약에 반영된다.
- 가상 통화에서 mock 문장 대신 선택한 시나리오가 재생된다.
- 파일이 지정된 경우 재생 실패를 TTS 목소리로 대체하지 않는다.
- 사용자 생성 시나리오의 기존 생성, 녹음, 편집과 삭제 동작은 유지된다.
