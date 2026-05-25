# KORA Todo

## 완료
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

## 예정
- [ ] 리뷰 기능 테스트
- [ ] Now 탭 실제 이벤트 데이터
- [ ] Share 탭 UI 개선
