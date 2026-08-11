# App Store Screenshot Plan

## 캡처 기준

- 언어: `ko-KR`
- 기기: iPhone 17 Pro Max, iOS 26.5
- 방향: 세로
- 결과 크기: `1320 × 2868 px`
- 형식: JPEG(최고 품질), 알파 채널 없음
- 수량: 5장
- 출력: `fastlane/screenshots/ko-KR/`

Apple은 iPhone 앱에 1–10장의 스크린샷을 허용한다. 6.9형 최고 해상도 세트를 제공하면 App Store Connect가 더 작은 iPhone 크기에 맞게 축소할 수 있으므로, 첫 출시에서는 이 한 세트만 유지한다.

## 순서와 메시지

| 순서 | 파일 | 화면 | 전달할 메시지 |
| --- | --- | --- | --- |
| 01 | `01_phone_home.jpg` | 대화 선택 | 원하는 대화를 고르고 바로 가상 통화 시작 |
| 02 | `02_active_call.jpg` | 통화 중 | 실제 통화와 닮은 화면과 통화 중 SOS 접근 |
| 03 | `03_sos_actions.jpg` | SOS | 위치 공유, 문자 신고, 전화 신고의 명확한 선택 |
| 04 | `04_scenario_list.jpg` | 시나리오 | 기본 대화와 개인화한 대화를 한곳에서 관리 |
| 05 | `05_onboarding_safety.jpg` | 온보딩 | 통화를 끊지 않고 도움을 요청하는 핵심 가치 |

실제 사용자의 연락처, 위치, 통화 기록, 녹음 파일은 캡처 데이터에 사용하지 않는다. 스크린샷 전용 진입점은 Debug 빌드에서만 활성화된다.

## 실행

```sh
bundle install
bundle exec fastlane ios screenshots
```

다른 설치 환경에서는 다음과 같이 시뮬레이터를 지정할 수 있다.

```sh
TALKIE_SCREENSHOT_DEVICE="iPhone 17 Pro Max" \
TALKIE_SCREENSHOT_OS="26.5" \
bundle exec fastlane ios screenshots
```

App Store Connect 업로드는 캡처와 분리되어 있다. 검수 완료 후에만 다음 명령을 사용한다.

```sh
CONFIRM_SCREENSHOT_UPLOAD=YES bundle exec fastlane ios upload_screenshots
```
