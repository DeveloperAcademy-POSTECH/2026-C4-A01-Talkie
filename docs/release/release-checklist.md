# Talkie Release Checklist

## 현재 확인된 상태

- 앱 버전 / 빌드: `1.0 (1)`
- App Store 이름: `Talkie - 안심 가상통화`
- 앱 Bundle ID: `com.bk.spatial.talkie`
- 위젯 Bundle ID: `com.bk.spatial.talkie.Widget`
- App Group: `group.com.bk.spatial.talkie`
- iCloud Container: `iCloud.com.bk.spatial.talkie`
- 최소 iOS: 앱 `26.0`, 위젯 `26.5`
- 지원 기기: 앱은 iPhone 전용
- 스크린샷: 한국어 6.9형 5장 자동 생성 구성
- App Store Connect 앱 ID: `6798574594`

## 로컬 준비

- [x] `fastlane ios screenshots` 실행 및 5장 육안 검수
- [x] Fastlane `ios preflight` 최종 통과 (Fastlane 2.236.1, 2026-08-06)
- [ ] 실제 기기에서 가상 통화, 연속 무음 VAD, 백그라운드 오디오 확인
- [ ] 위젯 설치·실행과 Live Activity / Dynamic Island 확인
- [ ] 자동 녹음과 iCloud 동기화 켜기·끄기·삭제 확인
- [ ] 위치 공유, 112 문자, 112 전화의 확인 단계 점검
- [ ] Release 구성 Archive 성공
- [ ] 앱·위젯 버전과 빌드 번호 일치

## 계정과 서명 — 출시 전 차단 항목

프로젝트는 개인 Apple Developer 팀 `F6NWQ49U3H`의 Talkie 식별자 체계로 전환했다.

- [x] 개인 Apple Developer 팀의 앱 App ID
- [x] 위젯 App ID 등록
- [x] App Group 생성 및 양쪽 App ID 연결
- [x] iCloud Container 생성 및 앱 App ID에 CloudKit 연결
- [ ] CloudKit production schema 배포
- [ ] 배포 인증서와 App Store provisioning profile
- [x] 개인 App Store Connect의 앱 레코드 생성 (`Talkie - 안심 가상통화`, 2026-08-06)
- [x] Talkie 전용 App Store Connect API key 발급 및 Fastlane 조회 검증 (2026-08-06)

기존 팀의 iCloud Container 데이터는 자동으로 개인 팀 Container로 이동하지 않는다. 출시 계정이 확정되기 전에 실제 사용자 데이터를 만들지 않는 것이 안전하다.

## App Store Connect 메타데이터

- [x] 앱 이름(30자 이하), 부제(30자 이하) 초안
- [x] 설명, 키워드, 프로모션 문구 초안
- [x] 서포트 URL 공개 및 HTTPS 200 확인 (2026-08-06)
- [x] 개인정보 처리방침 URL 공개 및 HTTPS 200 확인 — iOS 앱 필수 (2026-08-06)
- [ ] 카테고리와 연령 등급
- [ ] 앱 개인정보: 연락처, 위치, 오디오, 사용자 콘텐츠, iCloud 처리 여부
- [ ] 심사 노트: 가상 통화 목적, 마이크·위치 권한, 위젯, 녹음 테스트 방법
- [ ] 테스트용 계정이 필요하지 않다는 점 또는 필요한 접근 정보
- [ ] 수출 규정(암호화) 질문 답변

## 콘텐츠와 안전 검수

- [ ] “가상 통화”라는 표현을 앱과 스토어에서 일관되게 사용
- [ ] 실제 안전 보장 또는 범죄 예방을 암시하지 않음
- [ ] 즉각적인 위험에서는 112를 우선하도록 안내
- [ ] 녹음 시작 전 명확한 사용자 동의와 삭제 수단 제공
- [ ] 서포트 페이지에 녹음·위치·iCloud 범위 공개

## 빌드 경고 정리

- [x] `ScriptEditView`의 iOS 26 `Text + Text` 폐기 경고 2건을 `HStack` 구성으로 교체
- [x] `CallHistoryView`의 Main Actor 격리 경고 1건을 명시적인 `for` 반복문으로 교체
- [x] Release 시뮬레이터 빌드 성공 및 경고 출력 없음 (2026-08-06)

## Fastlane 운영 원칙

- 스크린샷 생성과 업로드를 분리한다.
- API 키, Apple ID, 팀 ID를 저장소에 커밋하지 않는다.
- `upload_screenshots`는 `CONFIRM_SCREENSHOT_UPLOAD=YES`가 없으면 중단한다.
- TestFlight, 메타데이터, 스크린샷과 심사 제출 lane은 서로 분리하고 버전값 확인 잠금을 둔다.
- 새 앱 레코드는 App Store Connect 웹에서 생성한다. Apple의 Apps API는 새 앱 생성을 지원하지 않는다.
- 외부 변경 lane은 개인 팀·앱 레코드와 API 키 연결을 확인한 뒤 실행한다.

## AirGiggle 방식 적용 상태

- [x] 제품 소개·지원·개인정보 처리방침을 `site/`로 구성
- [x] GitHub Pages workflow 준비
- [x] 한국어 App Store 메타데이터와 영문 심사 노트를 파일로 관리
- [x] 앱·위젯·App Group·CloudKit·아이콘·스크린샷을 검사하는 `preflight` lane 구성
- [x] App Store Connect API key와 심사 담당자 정보를 환경변수로 분리
- [x] 개인 GitHub Pages 경로 `https://lepurecafe.github.io/Talkie/` 공개 (2026-08-06)
- [x] 개인 Apple Developer 식별자로 프로젝트와 Fastlane 기본값 통일 (2026-08-06)
