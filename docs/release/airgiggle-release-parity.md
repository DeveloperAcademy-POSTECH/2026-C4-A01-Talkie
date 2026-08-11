# Talkie Release Preparation — AirGiggle Parity

## 적용한 운영 방식

AirGiggle 출시 저장소의 다음 구조를 Talkie에 맞게 적용한다.

- `site/`: 제품 소개, 지원, 개인정보 처리방침을 하나의 정적 사이트로 관리
- `.github/workflows/pages.yml`: GitHub Pages 배포
- `fastlane/metadata/`: App Store 한국어 메타데이터와 심사 노트 버전 관리
- `fastlane/Fastfile`: 로컬 사전검증, 스크린샷, TestFlight, 메타데이터, 심사 제출을 독립 lane으로 분리
- 외부 변경 lane에 버전값 기반 명시적 확인 잠금 적용
- API 키와 심사 담당자 정보는 로컬 환경변수로만 전달

## Talkie에서 추가한 검증

Talkie는 AirGiggle과 달리 앱 확장, App Group, CloudKit, 마이크, 위치, 녹음과 백그라운드 오디오를 사용한다.

- 앱과 위젯 Bundle ID 일치 확인
- 두 타깃의 Team ID와 App Group 일치 확인
- 앱의 CloudKit container와 service entitlement 확인
- 5장 스크린샷 수량, 1320x2868 크기와 알파 채널 확인
- 지원 페이지와 심사 노트에 발화 감지, 자동 녹음, 위치, 112, iCloud 범위를 명시

## 공개 전 남은 조건

- 개인 Apple Developer Team의 최종 Bundle ID, Widget ID, App Group, iCloud Container 확정
- App Store Connect 앱 레코드 생성
- CloudKit production schema 배포 및 실제 기기 간 동기화 QA
- GitHub Pages 공개 후 support/privacy/marketing URL의 HTTPS 200 확인
- App Privacy와 연령 등급 답변을 실제 구현 및 개인정보 처리방침과 일치시킴
- 실제 기기에서 가상 통화, VAD, 자동 녹음, 백그라운드 오디오, 위젯, Live Activity, 위치 공유, 112 흐름 확인

현재 메타데이터 URL은 AirGiggle과 같은 개인 GitHub Pages 패턴인 `https://lepurecafe.github.io/Talkie/`를 사용한다. 사이트를 공개하기 전에는 App Store Connect에 업로드하지 않는다.
