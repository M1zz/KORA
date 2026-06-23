# KORA Todo

## 완료
- [x] Google Analytics(Firebase) 수집 활성화: Firebase SDK(SPM) 연동, KORAApp에 FirebaseApp.configure()
- [x] GA 데이터 미수집 근본 원인 수정: 앱 타깃에 OTHER_LDFLAGS=-ObjC 추가(정적 Analytics 등록 누락) + Info.plist FIREBASE_ANALYTICS_COLLECTION_ENABLED=YES. 시뮬레이터 실행으로 first_open/session_start 이벤트 기록·measurement DB 생성 확인
- [x] 빌드 에러 수정
- [x] Deprecated Map API 교체 (Map(position:) + Annotation + MapPolyline)
- [x] 일본어 기본 / 한국어 번역 (Localizable.xcstrings)
- [x] 더미 데이터 제거 (Place.samples, Review.samples, NowEvent.samples)
- [x] PlaceStore 공유 데이터 레이어 (UserDefaults 퍼시스턴스)
- [x] 카카오 로컬 API 통합 (KakaoLocalService, KakaoConfig)
- [x] Instagram/YouTube/X 링크 파싱 (OG 태그)
- [x] Apple Maps 경로 안내 (MKDirections, MKMapItem.openInMaps)
- [x] Go 탭 네비게이션 바 타이틀 제거
- [x] 클립보드 링크 감지 → "추가할까요?" 배너 프롬프트
- [x] 링크 추가 + FAB 버튼 (AddPlaceSheet)
- [x] 100% 로컬라이제이션 완성 (일본어 기본 / 한국어 번역)

## 진행 중
- [ ] 카카오 Developer Console 서비스 활성화 필요
  - 카카오맵 서비스 활성화 (developers.kakao.com)
  - iOS 플랫폼 등록: bundle ID `com.kora.leeo`

- [x] 지하철 탭 → 종합 대중교통 탭 (路線図 + 料金・時間 + 漢江バス)
  - PDFKit으로 서울 지하철 노선도 표시 (서울 메트로 공식 PDF)
  - 기본 운임 표 (어른/청소년/어린이 × 카드/현금)
  - 운행 시간 (1~9호선, 공항철도, 신분당선 등)
  - 환승 규칙, 노선 색상 가이드
  - 한강버스 주요 나루터, 요금, 이용 팁

## 완료 (v1.0.1)
- [x] 앱 버전 1.0.1 / 빌드 2로 상향 (전 타깃)
- [x] 지하철 출발·정차 동기화 강화 — 4중 소스 융합 + 안전 장치
  - 서울 열린데이터광장 실시간 도착 API 연동 (RealtimeArrivalService → TransitPositionTracker)
    - 종착역/열차번호 기반 방향·열차 식별, 다음 역 도착/접근 확정
    - SeoulTransitConfig + Secrets(SEOUL_OPEN_API_KEY) + Info.plist 주입, 키 없으면 자동 폴백
  - 안전 장치: 단조 증가, 종점 클램프, 가속도계 과다카운트 캡(maxMotionLead),
    GPS 노후 fix 무시(90s), 실시간 게이트(드리프트 ±1역 제한), 신뢰도 등급
  - UI: 실시간 "다음 역 접근 중" 배지, 저신뢰 시 "위치 보정" 안내
  - Info.plist NSMotionUsageDescription 추가

## 완료 (네비게이터 UI 개선)
- [x] 탑승 전: "탑승 전" 배지 오른쪽에 "X호선 ○○행" 표기 추가
- [x] 탑승 중: "탑승 중" 상태 배지 표시 (호선·방면 함께)
- [x] "여기가 아니라면 탭해서 역 바꾸기"(tapToFixPosition) 문자열 제거
- [x] 탑승 중 현재역 카드 오른쪽에 위치 핀 버튼 → 위치 보정 시트 열기
- [x] 적응형 진행 다이어그램(inTransitProgressVisual): 2정거장 이하 전체 표시, 그보다 멀면 "현재 ⋯ 목적지"로 축약, 가까워질수록 역 확장

## 예정
- [ ] 서울 열린데이터광장 실시간 도착 API 키 발급 후 Secrets.xcconfig에 입력
- [ ] 리뷰 기능 테스트
- [ ] Now 탭 실제 이벤트 데이터
- [ ] Share 탭 UI 개선
