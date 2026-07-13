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

## 완료 (v1.0.4)
- [x] 앱 버전 1.0.4 / 빌드 5로 상향 (전 타깃)
- [x] 피드백: GTX-A 노선 추가 (킨텍스 포함, 운정중앙↔서울역 / 수서↔동탄 분리 구간,
      실시간 도착 subwayId 1032, 시각표, 환승 도보시간)
- [x] 전국 지하철 확대 (동일 메커니즘: 노선 데이터 + 좌표 + 일/영/중 표기 + 시각표)
  - 수도권 신규: 경춘선, 경강선, 서해선, 김포골드라인, 신림선, 우이신설선,
    의정부경전철, 용인에버라인, 인천 1호선(검단연장 포함)·2호선
  - 수도권 보정: 1호선 연천 연장·광명셔틀, 5호선 강일, 6호선 응암순환 개별역
    (선형 꼬리 근사), 7호선 산곡·석남, 경의중앙선 홍대입구 누락 수정·
    신촌(경의중앙) 분리·서울역지선 추가, 5호선 양평→양평(서울) 개명
  - 지방: 부산 1~4호선·부산김해경전철·동해선, 대구 1~3호선·대경선,
    광주 1호선, 대전 1호선 — 총 928역/36개 노선 엔트리
  - MetroRegion 도입: 권역 간 환승·경로 차단 검증(0건), 동명이역 개명
    (시청(부산)·용문(대전)·부전(동해선) 등 ~30건), 실시간 API 조회 시 괄호 제거
  - 데이터 생성 스크립트 + 리서치 원본: scripts/station-data/ (재생성 가능)
  - 검증: 전 역 좌표/표기 존재, 사전 중복 키 0, 번역 마커 예외 등록,
    경로 탐색 스모크 테스트 (킨텍스→명동 = GTX-A→4호선 등 12케이스)
- [x] 지역 카테고리 (서울/경기·인천·부산·대구·광주·대전): 역 선택 화면 상단 칩,
      @AppStorage 영구 저장, 둘러보기는 선택 권역만·검색은 전국

## 예정
- [ ] 서울 열린데이터광장 실시간 도착 API 키 발급 후 Secrets.xcconfig에 입력
- [ ] 리뷰 기능 테스트
- [ ] Now 탭 실제 이벤트 데이터
- [ ] Share 탭 UI 개선
